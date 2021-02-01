
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class JudgeCam : UdonSharpBehaviour
{
    public UdonBehaviour Machine;//CustomEventはこれで取れる
    private Camera cam;
    public RenderTexture rendertexture;
    public Texture2D tex;

    void Start(){
        cam = this.GetComponent<Camera>();
    }
    
    //ReadPixelsを使うためにOnPostRender()で実行する
    void OnPostRender(){
        tex.ReadPixels(cam.pixelRect, 0, 0, false);
        tex.Apply(false);
        /*
        float isHit = tex.GetPixel(0, 0).a;
        if(isHit==0.8f) {
            //tex.SetPixel(0,0, new Color(0,0,0,0));
            Send();
        }*/
        float isHit = tex.GetPixel(0, 0).a+tex.GetPixel(1, 0).a+tex.GetPixel(0, 1).a+tex.GetPixel(1, 1).a;
        //if(isHit>2.5) Send();
        //*
        if(isHit>2.5) {
            Send();
            for(int i=0;i<2;i++){
                for(int j=0;j<2;j++){
                    tex.SetPixel(i,j, new Color(0,0,0,0));
                }
            }
            tex.Apply(false);
        }
        // */
    }

    void Send(){
        Machine.SendCustomEvent("GameOver");
        //Machine.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NextState");
        //Machine.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "JumpStateFalse");
    }
}
