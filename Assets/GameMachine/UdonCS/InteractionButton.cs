
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class InteractionButton : UdonSharpBehaviour
{
    [SerializeField] private UdonBehaviour Machine;//CustomEventはこれで取れる
    private float time = 0.0f;
    private Collider boxcollider;
    private bool isSynced = false;

    void Start(){
        boxcollider = this.GetComponent<BoxCollider>();
        if(!Networking.IsMaster){
            boxcollider.enabled = false;
        }
    }

    void Update(){
        if(!Networking.IsMaster & isSynced==false){
            time += Time.deltaTime;
            if(time>10.0f) {
                boxcollider.enabled = true;
                isSynced = true;
            }
        }
    }
    
    public override void Interact(){
        Send();
    }

    void Send(){
        Machine.SendCustomEvent("ReceiveInteract");
    }
}
