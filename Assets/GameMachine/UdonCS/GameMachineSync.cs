using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class GameMachineSync : UdonSharpBehaviour
{
    [SerializeField] private Text playername;
    [SerializeField] private Text rankingViewer;
    [SerializeField] private GameObject display,judgecam,collidercube,InterButton;
    public Text debugview;
    [UdonSynced] private float firstTime, secondTime, thirdTime, nowTime;
    [UdonSynced] private int seed_now, seed_next = 0;
    [UdonSynced] private int firstId, secondId, thirdId, NowPlayerID;
    private VRCPlayerApi localplayer;
    private Material matdisplay, matbutton, matInter;
    private Vector3 campos, colliderpos;
    private float y, time, height, totalTime = 0.0f;
    private float PI = 3.14159265359f;
    public bool isJamp,isSetRanking,isLateJoiner,isForceSync = false;
    private int seed_orig, gamestate = 0;
    private string[] playerNames = new string[4];
    private float[] playerTimes = new float[4];
    private int[] playerIds = new int[4];
    private VRCPlayerApi[] players;
    public int MaxPlayerCount = 30;

    // 初期化
    void Start(){
        if (Networking.LocalPlayer != null){
            localplayer = Networking.LocalPlayer;
        }
        players = new VRCPlayerApi[MaxPlayerCount];
        matdisplay = display.GetComponent<MeshRenderer>().material;
        matbutton = this.GetComponent<MeshRenderer>().material;
        matInter = InterButton.GetComponent<MeshRenderer>().material;
        campos = judgecam.transform.position;
        colliderpos = collidercube.transform.position;
        y = campos.y;
        if(Networking.IsMaster){
            seed_orig = System.DateTime.Now.Year + System.DateTime.Now.Month * System.DateTime.Now.Day;
            seed_now = seed_orig;
            seed_next = seed_orig;
        }
        for(int i=0; i<=3; i++){
            playerTimes[i] = 0.0f;
            playerNames[i] = "_";
            playerIds[i] = -1;
        }
        SetRanking();
    }
    // プレイヤーがJoinしたときの処理. Masterがワールドに入った時も実行される.
    public override void OnPlayerJoined(VRCPlayerApi player) {
        if(Networking.LocalPlayer == player){
            localplayer = Networking.LocalPlayer;
        }
        if(!Networking.IsMaster){
            isLateJoiner = true;
            matdisplay.SetInt("_isLate", 1);
        }
        players = VRCPlayerApi.GetPlayers(players);
    }

    // 毎フレーム実行される
    void Update(){
        SetDebugView();
        if(isLateJoiner){
            time += Time.deltaTime;
            if(time>=10.0f){
                ResetAllTime();
                SetRankingforLateJoiner();
                isLateJoiner = false;
                matdisplay.SetInt("_isLate", 0);
                return;
            }
        }
        if(isForceSync){
            totalTime += Time.deltaTime;
            if(totalTime>5.0f){
                totalTime = 0.0f;
                players = VRCPlayerApi.GetPlayers(players);
                SetRankingforLateJoiner();
                isForceSync=false;
                ResetGameState();
            }
            matdisplay.SetFloat("_TotalTime", totalTime);
            return;
        }
        if(gamestate==0){ //待機画面
            totalTime += Time.deltaTime;
            if(Networking.IsOwner(this.gameObject)){
                time += Time.deltaTime;
                if(time>=2.0f){
                    time=0.0f;
                    SetNowPlayerID();
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetDisplayName");
                }
                matInter.SetColor("_Color", new Color(0.0f, 1.0f, 0.0f));
            }else{
                matInter.SetColor("_Color", new Color(1.0f, 0.0f, 0.0f));
            }
        }else if(gamestate==1){ //開始前のカウントダウン
            totalTime += Time.deltaTime;
            if(totalTime>=2.998f){
                if(Networking.IsOwner(this.gameObject)){
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetNextState");
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetAllTime");
                }
                matdisplay.SetFloat("_TotalTime", totalTime);
                return;
            }
        }else if(gamestate==2){ //ゲーム中
            totalTime += Time.deltaTime;
            
            if(Networking.IsOwner(this.gameObject)){
                var cubepos = localplayer.GetBonePosition(HumanBodyBones.RightIndexDistal);
                collidercube.transform.position = cubepos;
            }

            if(isJamp){
                time += Time.deltaTime;
                height = Mathf.Sin(mypow(PI * time, 0.8f));
                height = Mathf.Clamp01(mypow(height, 1.0f) * 0.5f);
                campos.y = y + height*0.3f;
                judgecam.transform.position = campos;

                if(time>=1.0 || height<=0.0) {
                    JumpStateFalse();
                }
            }
        }else if(gamestate==3){ //ゲームオーバー
            time += Time.deltaTime;
            if(isSetRanking==false){
                if(time>=3.0f){
                    SortRanking();
                    SetRanking();
                    isSetRanking = true;
                    totalTime = nowTime;
                }
            }
            if(Networking.IsOwner(this.gameObject)){
                if(isSetRanking & time>=2.0f){
                    time=0.0f;
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetDisplayName");
                }
            }
        }
        totalTime = gamestate==3 ? nowTime : totalTime;
        matdisplay.SetFloat("_Jump", height);
        matdisplay.SetFloat("_TotalTime", totalTime);
        Color buttonCol = isJamp ? new Color(1.0f, 1.0f, 0.0f) : new Color(0.0f, 0.0f, 1.0f);
        matbutton.SetColor("_Color", buttonCol);
    }

    //https://light11.hatenadiary.com/entry/2020/01/17/001035
    public float mypow(float src, float x){
        return src - (src - src * src) * -x;
    }
    float RoundFloat(float num){
        num = num * 100f;
        num = Mathf.Floor(num) / 100f;
        return num;
    }

    //https://techblog.kayac.com/comparing-random-number-generator
    int XorShift(int seed){
        uint _x = 0xffff0000 | (uint)(seed & 0xffff);
        _x = _x ^ (_x << 13);
        _x = _x ^ (_x >> 17);
        _x = _x ^ (_x << 5);
        return (int)(_x & 0xffff);
    }
    public void SetRand(){
        seed_now = seed_next;
        seed_next = XorShift(seed_now);
        matdisplay.SetInt("_RandSeed", seed_now);
    }

    void SetDebugView(){
        string dbg =// "seed_orig : " + seed_orig.ToString() +"\n"
                     "seed_now  : " + seed_now.ToString() +"\n"
                    +"seed_next : " + seed_next.ToString() +"\n"
                    +"IsLateJoiner : "+ isLateJoiner.ToString() + "\n"
                    +"IsSetRanking : "+ isSetRanking.ToString() + "\n"
                    +"TotalTime : " + totalTime.ToString() + "\n"
                    +"time : " + time.ToString() + "\n"
                    +"firstname : " + playerNames[0] + "\n"
                    +"firstTime : " + firstTime.ToString() + "\n"
                    +"secondname : " + playerNames[1] + "\n"
                    +"secondTime : " + secondTime.ToString() + "\n"
                    +"thirdname : " + playerNames[2] + "\n"
                    +"thirdTime : " + thirdTime.ToString() + "\n"
                    +"playername : " + playerNames[3] + "\n"
                    +"nowTime : " + nowTime.ToString() + "\n"
                    +"MyPlayerID : " + localplayer.playerId.ToString() + "\n"
                    +"NowPlayerID : " + NowPlayerID.ToString() + "\n"
                    //+"playerIds[0] : " + playerIds[0].ToString() + "\n"
                    //+"playerIds[1] : " + playerIds[1].ToString() + "\n"
                    //+"playerIds[2] : " + playerIds[2].ToString() + "\n"
                    //+"playerIds[3] : " + playerIds[3].ToString() + "\n"
                    +"PlayerName & ID ↓↓↓" + "\n" ;
        for(int i=0; i<players.Length; i++){
            if(players[i]==null) break;
            dbg += players[i].displayName +" : "+ players[i].playerId.ToString() + "\n";
        }
        debugview.text = dbg;
    }

    public void JumpStateTrue(){
        isJamp = true;
    }
    void JumpStateFalse(){
        time = 0.0f;
        height = 0.0f;
        isJamp = false;
    }
    
    void SetCamActive(){
        judgecam.SetActive(true);
    }
    void SetCamInactive(){
        judgecam.SetActive(false);
    }
    public void SetNextState(){
        gamestate += 1;
        matdisplay.SetInt("_GameState", gamestate);
    }
    public void ResetGameState(){
        SetCamInactive();
        isJamp = false;
        isSetRanking = false;
        gamestate = 0;
        totalTime = 0.0f;
        time = 0.0f;
        matdisplay.SetInt("_GameState", gamestate);
    }
    public void ResetAllTime(){
        totalTime = 0.0f;
        time = 0.0f;
    }
    public void SetDisplayName(){
        if(isLateJoiner==false){
            for(int i=0; i<players.Length; i++){
                if(players[i]!=null){
                    if(players[i].playerId==NowPlayerID){
                        playername.text = "PlayerName:" + players[i].displayName;
                        break;
                    }
                }
            }
        }
    }

    void SetNowPlayerID(){
        NowPlayerID = localplayer.playerId;
    }

    public void GameOver(){
        SetCamInactive();
        collidercube.transform.position = colliderpos;
        nowTime = RoundFloat(totalTime);
        //nowTime = totalTime;
        if(Networking.IsOwner(this.gameObject)){
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetNextState");
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "JumpStateFalse");
        }
    }

    void BubbleSort(float[] num, int[] ids, string[] name){
        bool isEnd = false;
        int finAdjust = 1;
        while(!isEnd){
            bool isSwap = false;
            for (int i=0; i<num.Length-finAdjust; i++){
                if (num[i] < num[i+1]){ //Swap開始
                    float tmp_num = num[i];
                    num[i] = num[i+1];
                    num[i+1] = tmp_num;
                    int tmp_ids = ids[i];
                    ids[i] = ids[i+1];
                    ids[i+1] = tmp_ids;
                    string tmp_name = name[i];
                    name[i] = name[i+1];
                    name[i+1] = tmp_name;
                    isSwap = true;
                }
            }
            if (!isSwap){ //Swapが一度も実行されなかった場合はソート終了
                isEnd = true;
            }
            finAdjust++;
        }
    }

    public void SortRanking(){
        playerTimes[3] = nowTime;
        playerIds[3] = NowPlayerID;
        for(int i=0; i<players.Length; i++){
            if(players[i]!=null){
                if(players[i].playerId == NowPlayerID){
                    playerNames[3] = players[i].displayName;
                    break;
                }
            }
        }
        string tmp = playerNames[3];
        BubbleSort(playerTimes, playerIds, playerNames);
        playerTimes[3] = nowTime;
        playerNames[3] = tmp;
        //SetRanking();
    }
    public void SetRanking(){
        firstId  = playerIds[0]; firstTime  = playerTimes[0];
        secondId = playerIds[1]; secondTime = playerTimes[1];
        thirdId  = playerIds[2]; thirdTime  = playerTimes[2];
        string rankingText = "1st : "+playerNames[0] +"   "+ playerTimes[0].ToString("F2")  +"\n"
                            +"2nd : "+playerNames[1] +"   "+ playerTimes[1].ToString("F2") +"\n"
                            +"3rd : "+playerNames[2] +"   "+ playerTimes[2].ToString("F2")  +"\n"
                            +"now : "+playerNames[3] +"   "+ playerTimes[3].ToString("F2");
        rankingViewer.text = rankingText;
    }
    void SetRankingforLateJoiner(){
        playerIds[0] = firstId;  playerTimes[0] = firstTime;
        playerIds[1] = secondId; playerTimes[1] = secondTime;
        playerIds[2] = thirdId;  playerTimes[2] = thirdTime;
        
        for(int i=0; i<3; i++){
            if(playerIds[i]!=-1){
                for(int j=0; j<players.Length; j++){
                    if(players[j]!=null){
                        if(players[j].playerId==playerIds[i]){
                            playerNames[i] = players[j].displayName;
                            break;
                        }
                    }else{
                        playerNames[i] = "--John Doe--";
                    }
                }
            }else{
                break;
            }
        }

        for(int i=0; i<players.Length; i++){
            if(players[i]!=null){
                if(players[i].playerId == NowPlayerID){
                    playerNames[3] = players[i].displayName;
                    break;
                }
            }
        }
        playerTimes[3] = nowTime;
        string rankingText = "1st : "+playerNames[0] +"   "+ playerTimes[0].ToString("F2")  +"\n"
                            +"2nd : "+playerNames[1] +"   "+ playerTimes[1].ToString("F2") +"\n"
                            +"3rd : "+playerNames[2] +"   "+ playerTimes[2].ToString("F2")  +"\n"
                            +"now : "+playerNames[3] +"   "+ playerTimes[3].ToString("F2");
        rankingViewer.text = rankingText;
    }

    public void ReceiveInteract(){
        if(isForceSync==false){
            if(Networking.IsOwner(this.gameObject)){ //OwnerがInteractしたとき
                if(gamestate==0){ //初期状態
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetAllTime");
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetRand");
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetNextState");
                    SetCamActive();
                    SetNowPlayerID();
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetDisplayName");
                    return;
                }else if(gamestate==1){ //カウントダウン
                    return;
                }else if(gamestate==2){ //ゲーム中
                    return;
                }else if(gamestate==3){ //ゲームオーバー
                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetGameState");
                    return;
                }
            }else{  //Owner以外がInteractしたとき
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetGameState");
                Networking.SetOwner(Networking.LocalPlayer, this.gameObject);
                SetNowPlayerID();
                SetDisplayName();
                return;
            }
        }
    }

    public void SetIsForceSync(){
        isForceSync = true;
        matdisplay.SetInt("_GameState", 4);
    }

    public void ReceiveForceSync(){
        if(Networking.IsOwner(this.gameObject)){
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetGameState");
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SetIsForceSync");
        }
    }

    public void OnTriggerEnter(Collider t){
        //is Triggerをつける場合はOnTriggerEnter()を使う
        if(Networking.IsOwner(this.gameObject) & gamestate==2 & time==0.0f){
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "JumpStateTrue");
        }
    }

}
