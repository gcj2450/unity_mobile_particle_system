Shader "Unlit/ParticleCircle"
{
     SubShader {
        
         Pass {
             CGPROGRAM
 
             #pragma target 2.0
             #pragma vertex vert
             #pragma fragment frag
 
             struct fragmentInput {
                 float4 pos    : SV_POSITION;
                 float2 uv     : TEXCOORD0;
                 float3 normal : NORMAL;
             };
             
             struct vertexInput {
                float4 pos : POSITION;
                float2 id  : TEXCOORD2;
                float2 uv  : TEXCOORD0;
             };
             
             float randomHash(float p)
             {
                float HASHSCALE1 = 0.1031;
                
                while(float(p) / 10.f > 1.f) {
                    p = float(p) / 10.f;
                }
                
                float frac_p = frac(p);
                float3 p3 = float3(frac_p, frac_p, frac_p) * HASHSCALE1;
                p3 += dot(p3, p3.yzx + 19.19);
                
                return frac((p3.x + p3.y) * p3.z);
             }
             
             float randomSin(float2 _st) 
             {
                return frac(sin(dot(_st.xy, float2(12.9898f,78.233f)))*43758.5453123f);
             }
             
             float3 getPostion(float3 pos_initial, float time, float id)
             {
                // Parabola: P(t) = P0 + V0*t + 0.05*Acc*t2;

                float x = 0.f;
                for (int t = 0; t < 4; t++) {
                    x += randomHash(id);
                }
                x = x / 4.f;
                if (x > .5f) {
                    x = -1 * (x-.5f);
                }
               
                float y = 0.f;
                for (int t = 0; t < 4; t++) {
                    y += randomHash(randomHash(randomHash(id) * 100) * 100);
                }
                y = y / 4.f;
               
                float z = 0.f;
                for (int t = 0; t < 4; t++) {
                    z += randomHash(randomHash(id) * 100);
                }
                z = z / 4.f;
                if (z > .5f) {
                    z = -1 * (z-.5f);
                }

                float3 acc = float3(0.f, -9.81f, 0.f); // Gravity acceleration
                float3 v_initial = float3(x * 10, y * 5, z *10);
                
                return pos_initial + v_initial*time + 0.05f*acc*pow(time, 2); 
             }  
 
             fragmentInput vert (vertexInput v)
             {
                 fragmentInput o;

                 v.pos.xyz = getPostion(v.pos.xyz, v.id.y, v.id.x);
 
                 o.pos = UnityObjectToClipPos(v.pos);
                 o.uv  = v.uv.xy - fixed2(0.5, 0.5);

                 return o;
             }
 
             fixed4 frag(fragmentInput i) : SV_Target 
             {
                 float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                 
                 if (distance <= 0.5f) {
                     return fixed4(0, 1, 0, 1);
                 }
                 
                 discard;
                 return fixed4(0, 0, 0, 0); // just for compile reasons.
             }
             
             ENDCG
         }
    }
}