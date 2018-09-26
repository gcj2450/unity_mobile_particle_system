Shader "Unlit/ParticleCircle"
{
     SubShader {
        
         Pass {
             CGPROGRAM
 
             #pragma vertex vert
             #pragma fragment frag
 
             struct fragmentInput {
                 float4 pos : SV_POSITION;
                 float2 uv  : TEXTCOORD0;
             };
             
             struct vertexInput {
                float4  pos  : POSITION;
                float2  uv   : TEXCOORD0;
             };
 
             fragmentInput vert (vertexInput v)
             {
                 fragmentInput o;
 
                 o.pos = UnityObjectToClipPos(v.pos);
                 o.uv = v.uv.xy - fixed2(0.5, 0.5);
                 
                 return o;
             }
 
             fixed4 frag(fragmentInput i) : SV_Target 
             {
                 float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                 
                 if (distance <= 0.5f) {
                     return fixed4(0, 1, 0, 1);
                 }
                 
                 discard;
                 return fixed4(0, 0, 0, 0); // for compile reasons.
             }
             
             ENDCG
         }
    }
}