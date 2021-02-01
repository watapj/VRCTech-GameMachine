
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ForceSyncButton : UdonSharpBehaviour
{
    public UdonBehaviour Machine;//CustomEventはこれで取れる

    void Start(){
    }
    
    public override void Interact(){
        Send();
    }

    void Send(){
        Machine.SendCustomEvent("ReceiveForceSync");
    }
}
