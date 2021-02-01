Shader "WataOfuton/Game/Display_pre"
{
Properties
{
[NoScaleOffset]_Dino1("Dino 1", 2D) = "black" {}
[NoScaleOffset]_Dino2("Dino 2", 2D) = "black" {}
[NoScaleOffset]_Text1("Text1", 2D) = "black" {}
[NoScaleOffset]_Text2("Text2", 2D) = "black" {}
[NoScaleOffset]_Text3("Text3", 2D) = "black" {}
[NoScaleOffset]_NumberTex ("Numbertex",2D)= "black"{}
[NoScaleOffset]_JudgeTex ("Judge Render Texture", 2D) = "black" {}
_Jump("Jump", float) = 0.0
_TotalTime("Total Time", float) = 0.0
_RandSeed("Rand Seed", int) = 0
_GameState("Game State", int) = 0
}
SubShader
{
Tags { "Queue"="Geometry" }

Pass
{
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #include "UnityCG.cginc"

    struct appdata{
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f{
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    sampler2D _Dino1, _Dino2, _Text1, _Text2, _Text3, _JudgeTex, _NumberTex;
    float _Jump, _TotalTime;
    int _GameState, _RandSeed;

    v2f vert (appdata v){
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        //uvの原点をQuad中心にする
        o.uv = v.uv*2.0-1.0;
        //アス比の調整
        o.uv.x *= 1.0/0.666666; 
        return o;
    }

    /*
    [numbertex.shader]
    Copyright (c) [2018] [butadiene]
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
    https://twitter.com/butadiene121/status/1061325094532726784
    */
    float4 numbercol(float2 uv,float number,float maxdigits,float mindigits, float p){
        float paraline = 1.0;
        float dlines = 1.0;
        float digits = maxdigits+mindigits;
        float lines = paraline-dlines+1;
        number *= 100;
        
        float anumber= abs(number);
        
        maxdigits = maxdigits+2;

        float vp=frac(saturate(uv.y*paraline-(lines-1)));

        float u,n,value,v;
        digits = digits+1;
        float4 col=float4(0,0,0,1);
        
        [unroll]
        for(float i = 1; i < digits; ++i){
            u=frac(saturate(uv.x*digits-i));
            n = maxdigits-i;
            value =  frac(floor(anumber/pow(10.0,n))/10.0)*10.0;
            value= round(value);
            v = lerp(value/12.0,(value+1.0)/12.0,vp);
            col += tex2Dlod(_NumberTex, float4(u,v, 0,0));
        }

        float uten = frac(saturate(uv.x*digits-maxdigits+2));
        v = lerp(11.0/12.0,12.0/12.0,vp);
        col += p ? tex2Dlod(_NumberTex, float4(uten,v,0,0)) : 0.0;

        if(col.r<0.2) col = 0.0;
        return col;
    }
    /*
    float rand(float2 st){
        return frac(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453);
    }*/
    float rand(float seed){
        //int seed_now = XorShift(seed);
        return frac((float)seed/10000.0 * 43758.5453);
    }
    float N21(float2 p){
        p = frac(p*float2(123.34, 345.45));
        p += dot(p, p + 34.345);
        return frac(p.x*p.y);
    }

    float sdCircle(float2 uv, float size){
        return length(uv) - size;
    }
    float sdRoundedBox(float2 p, float2 b, float4 r){
        r.xy = (p.x>0.0)?r.xy : r.zw;
        r.x  = (p.y>0.0)?r.x  : r.y;
        float2 q = abs(p)-b+r.x;
        return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
    }
    float sdBox(float2 p, float2 b){
        float2 d = abs(p)-b;
        return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
    }
    float sdLine(float2 p, float2 a, float2 b){
        float2 pa = p-a, ba = b-a;
        float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
        return length( pa - ba*h );
    }

    //背景
    float4 Background(float2 uv){
        float pix = 100.0;
        uv = floor(uv*pix)/pix;
        float4 col = 0.8;
        float2 offs = float2(0.0, 0.4);
        
        float grid = 10.0;
        float2 uv0 = uv;
        uv0.x += _TotalTime + _RandSeed*100.0;
        float xid = floor(uv0.x*grid);
        //float r1 = rand(xid.xx);
        //float r1 = rand(xid);
        float r1 = N21(float2(xid, _RandSeed/10000.0));
        uv0.x = frac(uv0.x*grid) - 0.5;

        float d = sdLine(uv0+offs, float2(-0.5, 0.0), float2(0.5, 0.0));

        float d2 = sdLine(uv0+offs, float2(-0.5, 0.0), float2(-0.45, 0.0));
        d2 = min(d2, sdLine(uv0+offs, float2(-0.45, 0.0), float2(-0.25, 0.03)));
        d2 = min(d2, sdLine(uv0+offs, float2(-0.25, 0.03), float2( 0.25, 0.03)));
        d2 = min(d2, sdLine(uv0+offs, float2( 0.25, 0.03), float2( 0.45, 0.0)));
        d2 = min(d2, sdLine(uv0+offs, float2( 0.45, 0.0), float2( 0.5 , 0.0)));

        d = r1>0.85 ? d2 : d;
        col -= step(d, 0.01)*0.8;

        r1 = r1-0.5;
        float d3 = sdLine(uv0+offs, float2(-r1*0.4, -r1*0.1-0.1), float2(r1*0.4, -r1*0.1-0.1));
        col -= step(d3, 0.008)*0.8;

        float2 uv1 = uv;
        grid = 2;
        uv1.x += (_TotalTime + _RandSeed/1000.0)*0.7;
        float xid2 = floor(uv1.x*grid);
        //float r2 = rand(xid2.xx);
        //float r2 = rand(xid2);
        float r2 = N21(float2(xid2, _RandSeed/1000.0));
        uv1.x = frac(uv1.x*grid) - 0.5;

        //float r22 = rand(r2.xx);
        //float r22 = rand(r2);
        float r22 = N21(float2(r2, _RandSeed/1000.0));

        offs.y = r2*0.5;
        float d4 = sdLine(uv1-offs, float2(-0.3, 0.0), float2(0.3, 0.0));
        d4 = min(d4, sdLine(uv1-offs, float2(-0.3, 0.0), float2(-0.2, 0.03)));
        d4 = min(d4, sdLine(uv1-offs, float2(-0.2, 0.03), float2(-0.0, 0.03)));
        d4 = min(d4, sdLine(uv1-offs, float2( 0.0, 0.03), float2(0.2, 0.06)));
        d4 = min(d4, sdLine(uv1-offs, float2( 0.2, 0.06), float2(0.3, 0.00)));
        col -= r22<0.5 ? step(d4, 0.008)*0.2 : 0.0;

        col.a = 0.0;
        return col;
    }

    //キャラクター描画
    float4 Charactor(float2 uv, float scale){
        uv.x /= scale;
        float size = 0.75;
        float2 offs = float2(0.65, 0.35);
        float t = floor(fmod(_Time.y, 10)*10)%2.0;
        float4 cha = t==0.0 ? tex2D(_Dino1, float2(uv+offs)/size) : tex2D(_Dino2, float2(uv+offs)/size);;
        cha = step(0.1, cha);

        //キャラクターの部分だけalpha==0.5となる
        //他はalpha==0.0
        cha.a = cha.r*0.5;
        return cha;
    }

    //障害物描画
    float4 Enemy(float2 uv){
        float pix = 20.0;
        uv = floor(uv*pix)/pix;
        float4 col = 0.0;
        float2 size = float2(0.15, 0.6);
        float4 bounds = float4(0.2, 0.0, 0.2, 0.0);
        
        float e = sdRoundedBox(uv, size, bounds);
        float e2 = sdRoundedBox(uv-float2(0.375, 0.0), size*0.5, bounds);
        float e3 = sdBox(uv+float2(0.0, 0.3), float2(0.4, 0.05));
        float e4 = sdRoundedBox(uv+float2(0.375, 0.0), size*0.6, bounds);
        e2 = min(min(e2, e3), e4);
        e = min(e, e2);
        float4 Enemy = smoothstep(0.0, 0.001, e);

        //障害物の部分だけalpha==0.5となる
        //他はalpha==0.0
        Enemy.a = abs(Enemy.a-1.0)*0.5;
        return Enemy;
    }

    //待機画面
    float4 Standby(float2 uv){
        float4 col = 0.8;

        float2 uvt = uv*0.5+0.5;
        uvt.x = uvt.x/1.5 + 0.165;
        float time = floor(fmod(_Time.y*2.0, 2.0));
        col -= uv.y>0.0 ? tex2D(_Text1, uvt) : tex2D(_Text1, uvt)*time;

        col.a = 0.0;
        return saturate(col);
    }

    //カウントダウン
    float4 CountDown(float2 uv){
        float4 col = 0.8;

        float2 uvt = uv*0.5+0.5;
        uvt.x = uvt.x/1.5 + 0.165;
        col -= tex2D(_Text2, uvt);

        float2 offs = float2(0.75, 0.5);
        float num = 3.999 - _TotalTime;
        col -= numbercol((uv+offs), num, 1,0, 0);

        float t = frac(_TotalTime);
        float d = length(uv) - 0.4;
        float c = smoothstep(0.001, 0.0, abs(d)-0.05);
        float m = atan2(-uv.x, -uv.y)/(3.1415*2.0) + 0.5;
        col = m-t>=0.0 ? col-c : col;
        
        col.a = 0.0;
        return saturate(col);
    }

    //プレイ中
    float4 PlayingNow(float2 uv){
        float4 col = Background(uv);

        //view totaltime
        float2 uvt = uv;
        float2 offs = float2(0.65, 0.535);
        float2 scales = float2(0.75, 0.225);
        col -= numbercol((uvt-offs)/scales, _TotalTime, 3,2, 1.0);

        //view [TIME:]
        uvt = uv-float2(0.275,-0.18);
        uvt = max(abs(uvt.x), abs(uvt.y-0.5))>0.5 ? 0.0 : uvt;
        col -= uvt.y>0.66 ? tex2Dlod(_Text3, float4(uvt,0,0)) : 0.0;

        //キャラクター描画
        float2 uv0 = uv;
        offs = float2(0.5*(1.0/0.666666), 0.3-_Jump);
        offs = float2(0.5, 0.3-_Jump);
        float scale = 0.5;
        float4 cha = Charactor(uv0+offs, scale);
        col.rgb -= cha.rgb;
        col.a += cha.a;

        //障害物の描画
        float2 uv1 = uv;
        float grid = 10.0;
        uv1.x += _TotalTime;
        float xid = floor(uv1.x*grid);
        xid = fmod(xid, 300.0);
        uv1.x = frac(uv1.x*grid) - 0.5;
        //float r1 = rand(xid.xx + (_RandSeed).xx);
        //float r1 = rand(xid + _RandSeed);
        float r1 = N21(float2(xid, _RandSeed));
        offs = float2(0.0, 0.3);
        uv1 = (uv1+offs)/float2(1., 0.2);
        float4 enemys = r1<0.1&&xid>15.0 ? Enemy(uv1) : 0.0;
        col = lerp(col, enemys, enemys.a*2.0);

        col.a = cha.a+enemys.a;
        return saturate(col);

    }

    //ゲーム\オーバー画面
    float4 GameOver(float2 uv){
        float4 col = 0.8;

        float time = fmod(_Time.y*2.0, 2.0);
        time = floor(time);
        float2 uvt = uv+float2(0.2, 0.5);
        float2 scale = float2(1.1, 0.6);
        col -= numbercol(uvt/scale, _TotalTime, 3,2, 1.0) * time;

        uvt = uv+float2(1.0, 0.7);
        scale = 2.0;
        uvt = max(abs(uvt.x-1.0), abs(uvt.y-0.5))>0.5*scale ? 0.0 : uvt;
        col -= uvt.y>0.66 ? tex2Dlod(_Text3, float4(uvt/2.0,0,0)) : 0.0;

        uvt = uv+float2(0.9, -0.08);
        uvt = max(abs(uvt.x-0.5), abs(uvt.y))>0.5 ? 0.0 : uvt;
        col -= tex2Dlod(_Text3, float4(uvt/1.8,0,0));

        //ゲームオーバー時はalpha==0.8
        //UDONがゲームオーバーになったことを検出するための値
        col.a = 1.0;
        return saturate(col);
    }

    float4 frag (v2f i) : SV_Target
    {
        float4 col = 0.0;
        float2 uv = i.uv;

        //UDONから渡されるStateから描画するSceneを決定
        if(_GameState==0){
            return Standby(uv);
        }else if(_GameState==1){
            return CountDown(uv);
        }
        
        /*
        //4ピクセルくらいで判定したほうがいいよね
        float judge = 0.0;
        float2 rd = float2(0.0, 1.0);
        judge += tex2D(_JudgeTex, rd.xx).a;
        judge += tex2D(_JudgeTex, rd.xy).a;
        judge += tex2D(_JudgeTex, rd.yx).a;
        judge += tex2D(_JudgeTex, rd.yy).a;
        if(judge>=2.5 || _GameState==3) {
            return GameOver(uv);
        }
        */
        if(_GameState==3){
            return GameOver(uv);
        }

        return PlayingNow(uv);
    }
    ENDCG
}
Pass {
    Name "ShadowCaster"
    Tags {
        "LightMode"="ShadowCaster"
    }
    Offset 1, 1
    Cull off

    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #include "UnityCG.cginc"
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    #pragma only_renderers d3d9 d3d11 glcore gles
    struct VertexInput {
        float4 vertex : POSITION;
    };
    struct VertexOutput {
        V2F_SHADOW_CASTER;
    };
    VertexOutput vert (VertexInput v) {
        VertexOutput o = (VertexOutput)0;
        o.pos = UnityObjectToClipPos( v.vertex );
        TRANSFER_SHADOW_CASTER(o)
        return o;
    }
    float4 frag(VertexOutput i) : COLOR {
        SHADOW_CASTER_FRAGMENT(i)
    }
    ENDCG
}
}
}
