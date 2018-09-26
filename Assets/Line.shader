// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/LineShader"
{
     Properties {
         _Color ("Color", Color) = (1,0,0,0)
     }
     
     SubShader {
        
         Blend SrcAlpha OneMinusSrcAlpha
         Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

         Pass {
             CGPROGRAM
 
             #pragma vertex vert
             #pragma fragment frag
             #include "UnityCG.cginc"
 
             fixed4 _Color; // low precision type is usually enough for colors
 
             struct fragmentInput {
                 float4 pos : SV_POSITION;
                 float2 uv : TEXTCOORD0;
             };
 
             fragmentInput vert (appdata_base v)
             {
                 fragmentInput o;
 
                 o.pos = UnityObjectToClipPos (v.vertex);
                 o.uv = v.texcoord.xy - fixed2(0.5,0.5);
 
                 return o;
             }
 
             fixed4 frag(fragmentInput i) : SV_Target 
             {
                 float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                 
                 if (distance > 0.5f) {
                     return fixed4(1, 1, 1, 0);
                 } else {
                     return fixed4(0, 1, 0, 1);
                 }
             }
             ENDCG
         }
    }
}