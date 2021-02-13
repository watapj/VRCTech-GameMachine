Shader "WataOfuton/kaisetsu"
{
Properties
{
}
SubShader
{
Tags { "RenderType"="Opaque" }
LOD 100

Pass
{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
};

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    return o;
}

float4 frag (v2f i) : SV_Target
{
    float4 col = 1.0;
    float2 uv = i.uv*2.0-1.0;
    uv.x *= 1.0/0.666666;

    float grid = 8.0;
    uv.x+=2.0;
    float xid = floor(uv.x*grid)/grid/grid;
    //xid = fmod(xid, 500);
    uv.x = frac(uv.x*grid);

    col.rg = uv.y<0.0 ? xid : uv;
    col.b = uv.y<0.0 ? xid : 0;

    return col;
}
ENDCG
}
}
}
