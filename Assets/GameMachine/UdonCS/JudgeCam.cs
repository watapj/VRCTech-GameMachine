
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class JudgeCam : UdonSharpBehaviour
{
    [SerializeField] private UdonBehaviour Machine;//CustomEventはこれで取れる
    private Camera cam;
    [SerializeField] private RenderTexture rendertexture;
    [SerializeField] private Texture2D tex;

    void Start(){
        cam = this.GetComponent<Camera>();
    }
    
    //ReadPixelsを使うためにOnPostRender()で実行する
    void OnPostRender(){
        tex.ReadPixels(cam.pixelRect, 0, 0, false);
        tex.Apply(false);
        
        float isHit = tex.GetPixel(0, 0).a+tex.GetPixel(1, 0).a+tex.GetPixel(0, 1).a+tex.GetPixel(1, 1).a;
        if(isHit>=2.5) {
            Send();
            //テクスチャを初期化
            for(int i=0;i<2;i++){
                for(int j=0;j<2;j++){
                    tex.SetPixel(i,j, new Color(0,0,0,0));
                }
            }
            tex.Apply(false);
        }
    }

    void Send(){
        Machine.SendCustomEvent("GameOver");
    }
}
