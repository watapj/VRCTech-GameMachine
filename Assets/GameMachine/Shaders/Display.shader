Shader "WataOfuton/Game/Display"
{
Properties
{
[NoScaleOffset]_Chara1("Charactor 1", 2D) = "black" {}
[NoScaleOffset]_Chara2("Charactor 2", 2D) = "black" {}
[NoScaleOffset]_Text0("Text 0", 2D) = "black" {}
[NoScaleOffset]_Text1("Text 1", 2D) = "black" {}
[NoScaleOffset]_Text2("Text 2", 2D) = "black" {}
[NoScaleOffset]_Text3("Text 3", 2D) = "black" {}
[NoScaleOffset]_Text4("Text 4", 2D) = "black" {}
[NoScaleOffset]_Text5("Text 5", 2D) = "black" {}
[NoScaleOffset]_Text6("Text 6", 2D) = "black" {}
[NoScaleOffset]_Text7("Text 7", 2D) = "black" {}
[NoScaleOffset]_Text8("Text 8", 2D) = "black" {}
[NoScaleOffset]_Text9("Text 9", 2D) = "black" {}
[NoScaleOffset]_Text10("Text10", 2D) = "black" {}
[NoScaleOffset]_Enemy("Enemy", 2D) = "black" {}
[NoScaleOffset]_NumberTex ("Numbertex",2D)= "black"{}
_Jump("Jump", float) = 0.0
_TotalTime("Total Time", float) = 0.0
_RandSeed("Rand Seed", int) = 0
_GameState("Game State", int) = 0
_isLate("is Late Joiner", int) = 0
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

    v2f vert (appdata v){
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        return o;
    }
    
    sampler2D _Chara1, _Chara2, _Text0, _Text1, _Text2, _Text3, _Text4, _Text5,
              _Text6, _Text7, _Text8, _Text9, _Text10, _Enemy, _NumberTex;
    float _Jump, _TotalTime;
    int _GameState, _RandSeed, _isLate;

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

        col = col.r<0.2 ? 0.0 : col;
        return col;
    }
    
    float N21(float2 p){
        p = frac(p*float2(123.34, 345.45));
        p += dot(p, p + 34.345);
        return frac(p.x*p.y);
    }

    float easingb(float x){
        return x*x*(2*x-1);
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
        
        //地面の描画準備
        float grid = 10.0;
        float2 uv0 = uv;
        uv0.x += _TotalTime + _RandSeed/1000.0;
        int xid = floor(uv0.x*grid);
        float r1 = N21(float2(xid, _RandSeed/1000.0));
        //float r1 = rand(xid, _RandSeed);
        uv0.x = frac(uv0.x*grid) - 0.5;

        //地平線
        float d = sdLine(uv0+offs, float2(-0.5, 0.0), float2(0.5, 0.0));
        float d2 = sdLine(uv0+offs, float2(-0.5, 0.0), float2(-0.45, 0.0));
        d2 = min(d2, sdLine(uv0+offs, float2(-0.45, 0.0), float2(-0.25, 0.03)));
        d2 = min(d2, sdLine(uv0+offs, float2(-0.25, 0.03), float2( 0.25, 0.03)));
        d2 = min(d2, sdLine(uv0+offs, float2( 0.25, 0.03), float2( 0.45, 0.0)));
        d2 = min(d2, sdLine(uv0+offs, float2( 0.45, 0.0), float2( 0.5 , 0.0)));
        //凸を描画するかどうか
        d = r1>0.85 ? d2 : d;
        col -= step(d, 0.01)*0.8;

        //地面の点々
        r1 = r1-0.5;
        float d3 = sdLine(uv0+offs, float2(-r1*0.4, -r1*0.1-0.1), float2(r1*0.4, -r1*0.1-0.1));
        col -= step(d3, 0.008)*0.8;

        //雲の描画準備
        float2 uv1 = uv;
        grid = 2;
        uv1.x += (_TotalTime + _RandSeed/1000.0)*0.7;
        float xid2 = floor(uv1.x*grid);
        float r2 = N21(float2(xid2, _RandSeed/1000.0));
        uv1.x = frac(uv1.x*grid) - 0.5;

        float r3 = N21(float2(r2, _RandSeed/1000.0));

        //雲の描画
        offs.y = r2*0.5;
        float d4 = sdLine(uv1-offs, float2(-0.3, 0.0), float2(0.3, 0.0));
        d4 = min(d4, sdLine(uv1-offs, float2(-0.3, 0.0), float2(-0.2, 0.03)));
        d4 = min(d4, sdLine(uv1-offs, float2(-0.2, 0.03), float2(-0.0, 0.03)));
        d4 = min(d4, sdLine(uv1-offs, float2( 0.0, 0.03), float2(0.2, 0.06)));
        d4 = min(d4, sdLine(uv1-offs, float2( 0.2, 0.06), float2(0.3, 0.00)));
        col -= r3<0.5 ? step(d4, 0.008)*0.2 : 0.0;

        col.a = 0.0;
        return col;
    }

    //キャラクター描画
    float4 Charactor(float2 uv){
        float2 scale = float2(0.4, 0.7);
        float2 offs = float2(1.0, 0.6-_Jump);
        float t = floor(fmod(_Time.y*8, 2));
        float2 chauv = (uv+offs)/scale;
        float4 cha = t==0.0 ? tex2Dlod(_Chara1, float4(chauv, 0,0)) : tex2Dlod(_Chara2, float4(chauv, 0,0));
        cha.rgb = step(cha.rgb, 0.1) * 0.8;

        //キャラクターの部分だけalpha=0.5とする
        //他はalpha=0.0
        cha.a = cha.a*0.5;
        return cha;
    }

    //障害物描画
    float4 Enemy(float2 uv){
        uv.y = (uv.y+1.5)/2.5;
        float4 enemy = tex2Dlod(_Enemy, float4(uv, 0,0));
        enemy.rgb = step(enemy.rgb, 0.1) * 0.8;
        //キャラクターの部分だけalpha=0.5とする
        //他はalpha=0.0
        enemy.a = enemy.a*0.5;
        return enemy;
    }

    //待機画面
    float4 Standby(float2 uv){
        float4 col = 0.8;

        if(_isLate){
            float time = floor(fmod(_Time.y, 1.0)*3.0);
            float4 text = tex2Dlod(_Text10, float4(uv-float2(0.0, 0.25),0,0));
            col -= (uv.x<0.68+0.03*time)&&uv.y<0.7 ? text : 0.0;
            col.a = 0.0;
            return col;
        }

        col -= uv.y>0.5 ? tex2Dlod(_Text0, float4(uv, 0,0)) : 0.0;

        //float time = fmod(_Time.y, 15);
        float time = fmod(max(_TotalTime, 0.0), 15);
        float slide1 = easingb(clamp(time- 3.8,  0, 1));
        float slide2 = easingb(clamp(time- 5.0, -1, 0)) + easingb(clamp(time- 8.8, 0, 1));
        float slide3 = easingb(clamp(time-10.0, -1, 0)) + easingb(clamp(time-13.8, 0, 1));
        float slide4 = easingb(clamp(time-15.0, -1, 0));

        if(uv.x>0.43){
            col -= tex2Dlod(_Text1, float4(uv.x-slide1, uv.y, 0, 0));
            col -= tex2Dlod(_Text2, float4(uv.x-slide2, uv.y, 0, 0));
            col -= tex2Dlod(_Text3, float4(uv.x-slide3, uv.y, 0, 0));
            col -= tex2Dlod(_Text1, float4(uv.x-slide4, uv.y, 0, 0));
        }
        float pics1 = tex2Dlod(_Text4, float4(uv.x, uv.y, 0, 0)).r;
        if(time<5){
            if(uv.x<0.21){
                col.gb -= pics1.rr * step(0.01, time-0.75);
            }else if(uv.x<0.29){
                col -= pics1.rrrr * step(0.01, time-1.5);
            }else{
                col.rb -= pics1.rr * step(0.01, time-2.25);
            }
        }else if(time<10){
            float tt = floor(fmod(time*2, 2));
            col -= tt==0 ? tex2Dlod(_Text5, float4(uv.x, uv.y, 0, 0)) : tex2Dlod(_Text6, float4(uv.x, uv.y, 0, 0));
        }else{
            float tt = floor(fmod(time*2.5, 2.5));
            col -= tt==0 ? tex2Dlod(_Text7, float4(uv.x, uv.y, 0, 0)) : tex2Dlod(_Text8, float4(uv.x, uv.y, 0, 0));
        }

        col.a = 0.0;
        return saturate(col);
    }

    //カウントダウン
    float4 CountDown(float2 uv){
        float4 col = 0.8;

        col -= tex2Dlod(_Text0, float4(uv-float2(0.0, 0.5), 0,0));

        float2 scale = 0.5;
        float2 offs = float2(0.128, 0.25-0.1);
        float num = 3.999 - _TotalTime;
        col -= numbercol((uv-offs)/scale, num, 1,0, 0);

        uv = uv*2.0-1.0;
        uv.x *= 1.0/0.666666; 
        uv.y += 0.2;

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
        uv = uv*2.0-1.0;
        //Displayアス比の調整
        uv.x *= 1.0/0.666666; 
        float4 col = Background(uv);

        col -= (_TotalTime<0.5 && uv.y<0.2) ? tex2Dlod(_Text9, float4(uv*0.5+float2(0.5, 0.1), 0,0)) : 0.0;

        //view totaltime
        float2 uvt = uv;
        float2 offs = float2(0.65, 0.535);
        float2 scales = float2(0.75, 0.225);
        col -= numbercol((uvt-offs)/scales, _TotalTime, 3,2, 1.0);

        //view [TIME:]
        uvt = uv-float2(0.275,0.29);
        uvt = max(abs(uvt.x), abs(uvt.y-0.7))>0.5 ? 0.0 : uvt;
        col -= uvt.y<0.5 ? tex2Dlod(_Text9, float4(uvt,0,0)) : 0.0;

        //キャラクター描画
        float2 uv0 = uv;
        float4 cha = Charactor(uv0);
        col = lerp(col, cha, cha.a*2.0);

        //障害物の描画
        float2 uv1 = uv;
        float grid = 8.0;
        uv1.x += _TotalTime;
        int xid = floor(uv1.x*grid);
        xid = fmod(xid, 500);
        uv1.x = frac(uv1.x*grid);
        float r1 = N21(float2((float)xid, _RandSeed/10000.0));

        float threshold = 0.1;
        //無理配置の回避
        float r0 = N21(float2((float)xid+1, _RandSeed/10000.0));
        float r2 = N21(float2((float)xid-1, _RandSeed/10000.0));
        float r3 = N21(float2((float)xid-2, _RandSeed/10000.0));
        float r4 = N21(float2((float)xid-3, _RandSeed/10000.0));
        float r5 = N21(float2((float)xid-4, _RandSeed/10000.0));

        r1 = (r1<threshold && r0>threshold && r3<threshold) ? 1.0 : r1;
        r1 = ((_TotalTime<60.0 || xid<480) && r2<threshold && r3<threshold && r5<threshold) ? 1.0 : r1;
        r2 = step(threshold, r2);
        r3 = step(threshold, r3);
        r4 = step(threshold, r4);
        r5 = step(threshold, r5);
        r1 = ((_TotalTime<30.0 || xid<250) && r2+r3+r4<=2) ? 1.0 : r1;

        offs = float2(0.0, 0.3);
        uv1 = (uv1+offs)/float2(1., 0.18);
        float4 enemys = r1<threshold&&xid>15 ? Enemy(uv1) : 0.0;
        col = lerp(col, enemys, enemys.a*2.0);

        col.a = 0.0;
        col.a = cha.a+enemys.a;
        return saturate(col);
    }

    //ゲームオーバー画面
    float4 GameOver(float2 uv){
        float4 col = 0.8;

        float time = fmod(_Time.y*2.0, 2.0);
        time = floor(time);
        float2 scale = float2(0.45, 0.3);
        float2 offs = float2(0.41, 0.22);
        col -= numbercol((uv-offs)/scale, _TotalTime, 3,2, 1.0) * time;

        col -= uv.y>0.2 ? tex2Dlod(_Text9, float4(uv,0,0)) : 0.0;

        col.a = 0.0;
        return saturate(col);
    }

    float4 ForceSync(float2 uv){
        float4 col = 0.8;
        float time = floor(fmod(_Time.y, 1.0)*3.0);
        float4 text = tex2Dlod(_Text10, float4(uv,0,0));
        col -= uv.x<0.68+0.03*time && uv.y>0.5 ? text : 0.0;

        float2 scale = 0.5;
        float2 offs = float2(0.128, 0.05);
        float num = 5.999 - _TotalTime;
        col -= numbercol((uv-offs)/scale, num, 1,0, 0);

        col.a = 0.0;
        return saturate(col);
    }

    float4 frag (v2f i) : SV_Target
    {
        float2 uv = i.uv; 

        //UDONから渡されるGameStateから描画するSceneを決定
        if(_GameState==0){
            return Standby(uv);
        }else if(_GameState==1){
            return CountDown(uv);
        }else if(_GameState==3){
            return GameOver(uv);
        }else if(_GameState==4){
            return ForceSync(uv);
        }
        //_GameState==2
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
//FallBack "Diffuse"
}
