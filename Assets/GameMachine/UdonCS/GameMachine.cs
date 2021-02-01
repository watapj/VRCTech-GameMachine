using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class GameMachine : UdonSharpBehaviour
{
    [SerializeField] private Text playername;
    [SerializeField] private Text rankingViewer;
    [SerializeField] private GameObject display,judgecam,collidercube,InterButton;
    private float firstTime, secondTime, thirdTime, nowTime;
    private int seed_now, seed_next, seed_orig, gamestate = 0;
    private VRCPlayerApi localplayer;
    private Material matdisplay, matbutton, matInter;
    private Vector3 campos, colliderpos;
    private float y, time, height, totalTime = 0.0f;
    private float PI = 3.14159265359f;
    public bool isJamp,isSetRanking, isEditor = false;
    private string[] playerNames = new string[4];
    private float[] playerTimes = new float[4];

    // 初期化
    void Start(){
        if (Networking.LocalPlayer != null){
            localplayer = Networking.LocalPlayer;
            isEditor = false;
        }else{
            isEditor = true;
        }
        matdisplay = display.GetComponent<MeshRenderer>().material;
        matbutton = this.GetComponent<MeshRenderer>().material;
        matInter = InterButton.GetComponent<MeshRenderer>().material;
        campos = judgecam.transform.position;
        colliderpos = collidercube.transform.position;
        y = campos.y;

        seed_orig = System.DateTime.Now.Year + System.DateTime.Now.Month * System.DateTime.Now.Day;
        seed_now = seed_orig;
        seed_next = seed_orig;

        for(int i=0; i<=3; i++){
            playerTimes[i] = 0.0f;
            playerNames[i] = "_";
        }
        SetRanking();
    }

    // 毎フレーム実行される
    void Update(){
        if(gamestate==0){ //待機画面
            totalTime += Time.deltaTime;
            matInter.SetColor("_Color", new Color(0.0f, 1.0f, 0.0f));
        }else if(gamestate==1){ //開始前のカウントダウン
            totalTime += Time.deltaTime;
            if(totalTime>=2.998f){
                SetNextState();
                ResetAllTime();
                return;
            }
        }else if(gamestate==2){ //ゲーム中
            totalTime += Time.deltaTime;
            
            if(isEditor==false){
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
        if(isEditor){
            playername.text = "PlayerName:" + "Editor Now";
        }else{
            playername.text = "PlayerName:" + localplayer.displayName;
        }
    }

    public void GameOver(){
        SetCamInactive();
        collidercube.transform.position = colliderpos;
        nowTime = RoundFloat(totalTime);
        SetNextState();
        JumpStateFalse();
    }

    void BubbleSort(float[] num, string[] name){
        bool isEnd = false;
        int finAdjust = 1;
        while(!isEnd){
            bool isSwap = false;
            for (int i=0; i<num.Length-finAdjust; i++){
                if (num[i] < num[i+1]){ //Swap開始
                    float tmp_num = num[i];
                    num[i] = num[i+1];
                    num[i+1] = tmp_num;
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
        string tmp;
        if(isEditor){
            tmp = "Editor Now";
        }else{
            tmp = localplayer.displayName;
        }
        playerNames[3] = tmp;
        BubbleSort(playerTimes, playerNames);
        playerTimes[3] = nowTime;
        playerNames[3] = tmp;
    }
    public void SetRanking(){
        firstTime  = playerTimes[0];
        secondTime = playerTimes[1];
        thirdTime  = playerTimes[2];
        string rankingText = "1st : "+playerNames[0] +"   "+ playerTimes[0].ToString("F2")  +"\n"
                            +"2nd : "+playerNames[1] +"   "+ playerTimes[1].ToString("F2") +"\n"
                            +"3rd : "+playerNames[2] +"   "+ playerTimes[2].ToString("F2")  +"\n"
                            +"now : "+playerNames[3] +"   "+ playerTimes[3].ToString("F2");
        rankingViewer.text = rankingText;
    }

    public void ReceiveInteract(){
        if(gamestate==0){ //初期状態
            ResetAllTime();
            SetRand();
            SetNextState();
            SetCamActive();
            SetDisplayName();
            return;
        }else if(gamestate==1){ //カウントダウン
            return;
        }else if(gamestate==2){ //ゲーム中
            return;
        }else if(gamestate==3){ //ゲームオーバー
            ResetGameState();
            return;
        }
    }

    public void OnTriggerEnter(Collider t){
        //is Triggerをつける場合はOnTriggerEnter()を使う
        if(gamestate==2 & time==0.0f){
            JumpStateTrue();
        }
    }

}
