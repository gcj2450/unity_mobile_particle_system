Shader "Unlit/ParticleCircle"
{
     SubShader {
        
         Pass {
             CGPROGRAM
 
             #pragma target 2.0
             #pragma vertex vert
             #pragma fragment frag
 
             static const float  HASHSCALE1 = 0.1031;
             static const float3 HASHSCALE3 = float3(.1031, .1030, .0973);
             static const float4 HASHSCALE4 = float4(.1031, .1030, .0973, .1099);
             static const float  ITERATIONS = 4.f;
 
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
                while(float(p) / 10.f > 1.f) 
                    p = float(p) / 10.f;
                
                float frac_p = frac(p);
                float3 p3 = float3(frac_p, frac_p, frac_p) * HASHSCALE1;
                p3 += dot(p3, p3.yzx + 19.19);
                
                return frac((p3.x + p3.y) * p3.z);
             }
             
             float3 hash31(float p) 
             {
                float3 p3 = frac(float3(p, p, p) * HASHSCALE3);
                p3 += dot(p3, p3.yzx+19.19);
                
                return frac((p3.xxy + p3.yzz)*p3.zyx); 
             }
             
             float randomSin(float2 _st) 
             {
                return frac(sin(dot(_st.xy, float2(12.9898f,78.233f)))*43758.5453123f);
             }
             
             // 'c' domain: (-1 <= c.xyz <= 1)
             // http://mathproofs.blogspot.com/2005/07/mapping-cube-to-sphere.html
             float3 mapCubeToSphere(float3 c)
             {
                float3 s = float3(0.f, 0.f, 0.f);
                
                s.x = c.x * sqrt(1 - pow(c.y, 2)/2 - pow(c.z, 2)/2 + (pow(c.y, 2)*pow(c.z,2))/3);
                s.y = c.y * sqrt(1 - pow(c.z, 2)/2 - pow(c.x, 2)/2 + (pow(c.x, 2)*pow(c.z,2))/3);
                s.z = c.z * sqrt(1 - pow(c.x, 2)/2 - pow(c.y, 2)/2 + (pow(c.x, 2)*pow(c.y,2))/3);
                
                return s;
             }
             
             float3 getPostion(float3 pos_initial, float time, float id)
             {
                float3 v = float3(0.f, 0.f, 0.f);

                float x = 0.f;
                for (int t = 0; t < ITERATIONS; t++) {
                    v += hash31(id);
                }
                v = v / ITERATIONS; // Normalize
                
                // Range from (0 <= x <= 1) to (-1 <= x <= 1)
                if (v.x > .5f) v.x = -1 * (v.x - .5f);
                if (v.y > .5f) v.y = -1 * (v.y - .5f);
                if (v.z > .5f) v.z = -1 * (v.z - .5f);
                v = 2 * v;
                
                // (optional)
                v = mapCubeToSphere(v);

                v = 10 * v; // Scale velocity
                
                float3 acc = float3(0.f, -9.81f, 0.f); // Gravity acceleration
                
                // Parabola: P(t) = P0 + V0*t + 0.05*Acc*t2;
                return pos_initial + v*time + 0.05f*acc*pow(time, 2); 
             }  
 
             fragmentInput vert (vertexInput v)
             {
                 fragmentInput o;

                 //@TODO find ways to improve this
                 v.pos.xyz += 0.0001f;
                 
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