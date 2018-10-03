Shader "Unlit/ParticleCircle"
{
    Properties {
        _ParticleSize ("Particle Size", Float) = 0.05
        _ParticleSpeedScale ("Particle Speed Scale", Float) = 10.0
    }
    
    SubShader {
       
        Pass {
            Cull Back

            CGPROGRAM
 
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            
            uniform float _ParticleSize = 0.05f;
            uniform float _ParticleSpeedScale = 10.f;
 
            static const float  HASHSCALE1 = 0.1031;
            static const float3 HASHSCALE3 = float3(.1031, .1030, .0973);
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
            
            /**
            * Calc new point position given its id and the current time.
            */
            float3 getNewPos(float3 initial_pos, float id, float time)
            {
                // Calc initial velocity/direction to a particle given its id.
                // >>> This number will be the same for each particle, in all frames. <<<
                float3 v = float3(0.f, 0.f, 0.f);
                for (int t = 0; t < ITERATIONS; t++) {
                    v += hash31(id);
                }
                v = v / ITERATIONS; // Normalize
               
                // Map range from (0 <= x <= 1) to (-1 <= x <= 1)
                if (v.x > .5f) v.x = -1 * (v.x - .5f);
                if (v.y > .5f) v.y = -1 * (v.y - .5f);
                if (v.z > .5f) v.z = -1 * (v.z - .5f);
                v = 2 * v;
               
                // (optional) particles will spread in a cube format without this.
                v = mapCubeToSphere(v);
               
                // Scale velocity
                v = _ParticleSpeedScale * v;
               
                // Gravity acceleration @TODO pass as paramenter from Unity UI.
                float3 acc = float3(0.f, -9.81f, 0.f); 
               
                // Apply Parabola equation: 
                // P(t) = P0 + V0*t + 0.05*Acc*t2;
                return initial_pos + v*time + 0.05f*acc*pow(time, 2); 
            }
            
            /**
            * Given an center point, calc quad vertex that corresponds to particle uv.
            * Billboard are orthogonal to the Main Camera and has _ParticleSize lenght.
            */
            float3 getBillboardVertex(float3 quad_center, float2 uv)
            {                
                float3 plane_normal = normalize(_WorldSpaceCameraPos - quad_center); 
                float plane_d = -dot(plane_normal, quad_center);
                float circumradius = sqrt(pow(_ParticleSize, 2) / 2.f);
                
                // Orthonormal basis vectors of the circle plane.
                float3 basis_vec1 = normalize(float3(0.f, 0.f, -(plane_d/plane_normal.z)) - quad_center);
                float3 basis_vec2 = normalize(cross(basis_vec1, plane_normal));

                // Based on uv, use clockwise rule and the basis to draw a square from center_pos.
                float3 v_pos = {0.f,0.f, 0.f};
                
                if(uv.x == 0) {
                    if(uv.y == 0) {
                        v_pos = quad_center - circumradius*basis_vec2;
                    } else if(uv.y == 1){
                        v_pos = quad_center - circumradius*basis_vec1;
                    }
                } else if(uv.x == 1) {
                    if(uv.y == 0) {
                        v_pos = quad_center + circumradius*basis_vec1;
                    } else if(uv.y == 1){
                        v_pos = quad_center + circumradius*basis_vec2;
                    }
                }
                
                return v_pos;
            }

            fragmentInput vert (vertexInput v)
            {
                // Get quad center new position (time has changed).
                float3 center_pos = getNewPos(v.pos, v.id.x, _Time.y);
                // With the center, get quad vertex position based on vertex uv.
                float3 v_pos = getBillboardVertex(center_pos, v.uv);

                // View transformation.
                fragmentInput o;
                o.pos = UnityObjectToClipPos(v_pos);
                o.uv  = v.uv.xy - fixed2(0.5, 0.5);

                return o;
            }
 
            fixed4 frag(fragmentInput i) : SV_Target 
            {
                // Discard pixels far from quad center: draw circle.
                float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                if (distance > 0.5f)
                   discard;

                return fixed4(0, 1, 0, 1);
            }
            
            ENDCG
        }
    }
}