Shader "Unlit/ParticleCircle"
{
    Properties {
        _RateOverTime ("Rate Over Time", Float) = 10
        _StartSize ("Size", Float) = 1.0
        _StartSpeed ("Start Speed", Float) = 5.0
        _StartLifeTime("Start Life Time", Float) = 5.0
        _StartDelay("Start Delay", Float) = 0.0
        _GravityModifier("Gravity Modifier", Float) = 0.0
        
        _StartColor("Start Color", Vector) = (0.0, 0.0, 0.0, 1.0)

        _Shape("Shape", int) = 0
        _ConeAngle("Cone Angle", Float) = 45.0
    }
    
    SubShader {
       
        Tags {"Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
       
        Pass {
            Cull Back

            CGPROGRAM
 
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            
            uniform float _StartSize = 1.0f;
            uniform float _RateOverTime = 10.f;
            uniform float _StartSpeed = 5.f;
            uniform float _StartLifeTime = 5.f;
            uniform float _StartDelay = 0.f;
            uniform float _GravityModifier = 0.0f;
            
            uniform float4 _StartColor = (0.f, 0.f, 0.f, 1.f);
            
            uniform int   _Shape = 0;
            uniform float _ConeAngle = 0.f;
 
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
            
            // Calc initial velocity/direction to a particle given its id.
            // Return an Float3 vec. Elements range: (0 <= p <= 1)
            // >>> This number will be the same for each particle, in all frames. <<<
            float3 getRandomVelocity(float id)
            {
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
               
                v = normalize(v);

                return v;
            }
            
            /**
            * Calc new point position given its id and the current time.
            */
            float3 sphereMovement(float3 initial_pos, float id, float time)
            {
                float3 v = getRandomVelocity(id);

                // Scale velocity
                v = _StartSpeed * v;
                
                return initial_pos + v*time;
            }
            
            /**
            * Calc new point position given its id and the current time.
            */
            float3 coneMovement(float3 initial_pos, float id, float time)
            {
                float3 v = getRandomVelocity(id);

                if (v.z < 0.f) v.z = -1 * v.z;
                
                float max_distance = v.z * tan(radians(_ConeAngle));

                v.x = max_distance * v.x;
                v.y = max_distance * v.y;
                
                v = normalize(v);
                
                // Scale velocity
                v = _StartSpeed * v;

                // Gravity acceleration @TODO pass as paramenter from Unity UI.
                float3 acc = float3(0.f, -_GravityModifier, 0.f);
               
                // Apply Parabola equation: 
                // P(t) = P0 + V0*t + 0.5*Acc*t2;
                return initial_pos + v*time + 4.f*acc*pow(time, 2); 
            }
            
            /**
            * Given an center point, calc quad vertex that corresponds to particle uv.
            * Billboard are orthogonal to the Main Camera and has _StartSize lenght.
            */
            float3 getBillboardVertex(float3 quad_center, float2 uv)
            {                
                float3 plane_normal = normalize(_WorldSpaceCameraPos - quad_center); 
                float plane_d = -dot(plane_normal, quad_center);
                float circumradius = sqrt(pow(_StartSize, 2) / 4.f);
                
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
                float3 v_pos = v.pos.xyz;
                float id = v.id.x;
                
                // _Time.y+1: id starts equal 1 and _Time.y equal 0. We want both starting together.
                float time = _Time.y + 1 - _StartDelay;

                // If a particle doesn't fit upper_bound, all vertices will be equal thus not rasterized.
                float upper_bound = time * _RateOverTime;
                
                if(id <= upper_bound) {
                    
                    // Relative time: particles must spawn from time equal zero.
                    float relative_time = time - (id / _RateOverTime);
                    
                    // Relative id to time window to increase randomness.
                    float r_id = id * randomSin(float2(id, id)) * (int)(relative_time / _StartLifeTime);
                    
                    // Normalize relative time.
                    relative_time = relative_time % _StartLifeTime;
                
                    float3 center_pos = float3(0.f, 0.f, 0.f);
                    if (_Shape == 0){
                        center_pos = coneMovement(v_pos, r_id, relative_time);
                    } else {
                        center_pos = sphereMovement(v_pos, r_id, relative_time);
                    }
                    
                    // Get quad center new position (time has changed).
                    // With the center, get quad vertex position based on vertex uv.
                    v_pos = getBillboardVertex(center_pos, v.uv);
                }
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
                
                float alpha = 1.f - (2*distance);
                
                return fixed4(_StartColor.xyz, alpha);
            }
            
            ENDCG
        }
    }
}