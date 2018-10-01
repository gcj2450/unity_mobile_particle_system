Shader "Unlit/ParticleCircle"
{
    SubShader {
       
        Pass {
            Cull Off

            CGPROGRAM
 
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
 
            static const float  HASHSCALE1 = 0.1031;
            static const float3 HASHSCALE3 = float3(.1031, .1030, .0973);
            static const float  ITERATIONS = 4.f;
 
            struct fragmentInput {
                float4 pos    : SV_POSITION;
                float2 uv     : TEXCOORD0;
                float3 normal : NORMAL;
            };
            
            struct vertexInput {
                float4 pos      : POSITION;
                float2 id_time  : TEXCOORD2;
                float2 uv       : TEXCOORD0;
            };
            
            // Hash functions to generate entropy by David Hoskins
            // https://www.shadertoy.com/view/4djSRW
            float hash11(float p)
            {
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
            
            // Generate entropy with Sin fn. For benchmark with hash functions
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
            
            int getMeshId(float vertex_id)
            {
                return ceil(vertex_id / 4);
            }
                        
            float3 RotateAroundZInDegrees(float3 vertex, float degrees)
            {
                float alpha = degrees * 3.14159 / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                //return float3(mul(m, vertex.xz), vertex.y).xzy;
                return float3(mul(m, vertex.xy), vertex.z).zxy;
            }
            
            float3 getPostion(float3 p, float time, float id)
            {
                float3 v = float3(0.f, 0.f, 0.f);

                float x = 0.f;
                for (int t = 0; t < ITERATIONS; t++) {
                    v += hash31(getMeshId(id));
                }
                    
                v = v / ITERATIONS; // Normalize
               
                // Range from (0 <= x <= 1) to (-1 <= x <= 1)
                if (v.x > .5f) v.x = -1 * (v.x - .5f);
                if (v.y > .5f) v.y = -1 * (v.y - .5f);
                if (v.z > .5f) v.z = -1 * (v.z - .5f);
                v = 2 * v;
               
                // (optional) particles will spread in a cube format without this.
                v = mapCubeToSphere(v);
               
                v = 10 * v; // Scale velocity @TODO: pass as param to shader.
               
                float3 acc = float3(0.f, -9.81f, 0.f); // Gravity acceleration
               
                // Parabola: P(t) = P0 + V0*t + 0.05*Acc*t2;
                return p + v*time + 0.05f*acc*pow(time, 2); 
            }  

            fragmentInput vert (vertexInput v)
            {
                fragmentInput o;

                float3 v_pos = {0.f, 0.f, 0.f};
                float particle_radius = 1;

                float3 center_pos = getPostion(float3(0, 0, 0), v.id_time.y, v.id_time.x);
                float3 circle_normal = normalize(_WorldSpaceCameraPos - center_pos); 
                float circumradius = sqrt(pow(particle_radius, 2) / 2.f);
                
                float circle_d = -dot(circle_normal, center_pos);
                
                // Orthonormal basis vectors of the circle plane.
                float3 vec1 = normalize(float3(0.f, 0.f, -(circle_d/circle_normal.z)) - center_pos);
                float3 vec2 = normalize(cross(vec1, circle_normal));

                // Based on uv, use clockwise rule and the basis to draw a square from center_pos.
                if(v.uv.x == 0) {
                    if(v.uv.y == 0) {
                        v_pos = center_pos - circumradius*vec2;
                    } else if(v.uv.y == 1){
                        v_pos = center_pos - circumradius*vec1;
                    }
                } else if(v.uv.x == 1) {
                    if(v.uv.y == 0) {
                        v_pos = center_pos + circumradius*vec1;
                    } else if(v.uv.y == 1){
                        v_pos = center_pos + circumradius*vec2;
                    }
                }

                // View transformation.
                o.pos = UnityObjectToClipPos(v_pos);
                o.uv  = v.uv.xy - fixed2(0.5, 0.5);

                return o;
            }
 
            fixed4 frag(fragmentInput i) : SV_Target 
            {
                float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));

                if (distance > 0.5f)
                   discard;

                return fixed4(0, 1, 0, 1);
            }
            
            ENDCG
        }
    }
}