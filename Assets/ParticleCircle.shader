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

        _CollisionPlaneCenter0("Collision Plane Center 0", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneNormal0("Collision Plane Normal 0", Vector) = (0.0, 0.0, 0.0, 0.0)
        
        _CollisionPlaneCenter1("Collision Plane Center 1", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneNormal1("Collision Plane Normal 1", Vector) = (0.0, 0.0, 0.0, 0.0)

        _CollisionPlaneCenter2("Collision Plane Center 2", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneNormal2("Collision Plane Normal 2", Vector) = (0.0, 0.0, 0.0, 0.0)

        _CollisionPlaneCenter3("Collision Plane Center 3", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneNormal3("Collision Plane Normal 3", Vector) = (0.0, 0.0, 0.0, 0.0)
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

            uniform float4 _StartColor = float4(0.f, 0.f, 0.f, 1.f);

            uniform int   _Shape = 0;
            uniform float _ConeAngle = 0.f;

            uniform float4 _CollisionPlaneCenter0 = float4(0.f, 0.f, 0.f, 1.f);
            uniform float4 _CollisionPlaneNormal0 = float4(0.f, 0.f, 0.f, 1.f);

            uniform float4 _CollisionPlaneCenter1 = float4(0.f, 0.f, 0.f, 1.f);
            uniform float4 _CollisionPlaneNormal1 = float4(0.f, 0.f, 0.f, 1.f);

            uniform float4 _CollisionPlaneCenter2 = float4(0.f, 0.f, 0.f, 1.f);
            uniform float4 _CollisionPlaneNormal2 = float4(0.f, 0.f, 0.f, 1.f);

            uniform float4 _CollisionPlaneCenter3 = float4(0.f, 0.f, 0.f, 1.f);
            uniform float4 _CollisionPlaneNormal3 = float4(0.f, 0.f, 0.f, 1.f);
 
            static const float  HASHSCALE1 = 0.1031;
            static const float3 HASHSCALE3 = float3(.1031, .1030, .0973);
            static const float  ITERATIONS = 4.f;
            static const float  PARABOLA_COEFFICIENT = 4.f;
            
            static float4 plane0_eq = float4(0.f, 0.f, 0.f, 0.f);
            static float4 plane1_eq = float4(0.f, 0.f, 0.f, 0.f);
            static float4 plane2_eq = float4(0.f, 0.f, 0.f, 0.f);
            static float4 plane3_eq = float4(0.f, 0.f, 0.f, 0.f);
 
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
            
            struct basis {
                float3 b0;
                float3 b1;
            };
            
            struct parabola {
                float3 v0;
                float3 v;
                float  t;
                float3 acc;
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
                if (v.x >= .5f) v.x = -1 * (v.x - .5f);
                if (v.y >= .5f) v.y = -1 * (v.y - .5f);
                if (v.z >= .5f) v.z = -1 * (v.z - .5f);
                v = 2.f * v;
               
                return normalize(v);
            }

            // Bhaskara method
            float2 solveQuadraticEquation(float3 coefficients)
            {
                float delta = pow(coefficients[1], 2) - 4*coefficients[0]*coefficients[2];
    
                if (delta < 0){
                    return float2(-1, -1);
                }

                float2 sol;
                sol[0] = (-coefficients[1] + sqrt(delta)) / (2*coefficients[0]);
                sol[1] = (-coefficients[1] - sqrt(delta)) / (2*coefficients[0]);

                return sol;
            }
            
            /**
            * Returns the time at which the intersection between plane and parabola occurs.
            * If return is < 0 there is no intersection.
            */
            float getCollisionTime(float4 plane_equation, parabola p)
            {
                float a = dot(plane_equation.xyz, p.acc) * PARABOLA_COEFFICIENT;
                float b = dot(plane_equation.xyz, p.v);
                float c = dot(plane_equation.xyz, p.v0) + plane_equation.w;
                
                if (a != 0){
                    // Has acceleration => quadratic
                    float2 time = solveQuadraticEquation(float3(a, b, c));
                    if (time[0] >= 0){
                        return time[0];
                    }
                    return time[1];
                } else {
                    // No acceleration => linear
                    return -c/b;
                }
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
            * Return float4(a, b, c, d) where 'ax + by + cy + d = 0'. 
            */
            float4 getPlaneEquation(float3 plane_normal, float3 plane_center)
            {
                float3 plane_n = normalize(plane_normal);
                float  plane_d = -dot(plane_n, plane_center);

                return float4(plane_n, plane_d);
            }
            
            /**
            * Return updated float4(normal.x, normal.y, normal.z, lower_time) if has collision in lower time.
            */
            float4 updateNearPlaneTime(float4 plane_equation, float4 lower_plane_normal_time, const parabola p)
            {
                if (plane_equation.x == 0.f && plane_equation.y == 0.f && plane_equation.z == 0.f){
                    // plane equation not set.
                    return lower_plane_normal_time;
                }
                
                const float time_threshold = 0.01f;

                float plane_collision_time = getCollisionTime(plane_equation, p);
                plane_collision_time = plane_collision_time - (_StartSize/10);
                
                // time_threshold prevents the particle go through the plane.
                if (plane_collision_time > time_threshold){
                    // actual time must be greater than collision time.
                    if (p.t > plane_collision_time){
                        // check if collision time found this plane is lower than that found with other planes.
                        if (plane_collision_time < lower_plane_normal_time.w){
                            // particle collision time outside plane.
                            plane_collision_time = plane_collision_time - time_threshold;
                            // set lower_plane_normal_time with lower time and plane normal.
                            lower_plane_normal_time = float4(plane_equation.xyz, plane_collision_time);
                        }
                    }
                }
                
                return lower_plane_normal_time;
            }
            
            /**
            * Given an initial parabola return new parabola after plane collisions.
            */
            parabola getParabolaAfterCollision(parabola p)
            {
                if (p.t <= 0.f){
                    return p;
                }
            
                float4 plane_normal_time = float4(0.f, 0.f, 0.f, _StartLifeTime);
                
                // Check collision Plane 0 and if its near emitter than the others.
                plane_normal_time = updateNearPlaneTime(plane0_eq, plane_normal_time, p);
                // Check collision Plane 1 and if its near emitter than the others.
                plane_normal_time = updateNearPlaneTime(plane1_eq, plane_normal_time, p);
                //// Check collision Plane 2 and if its near emitter than the others.
                plane_normal_time = updateNearPlaneTime(plane2_eq, plane_normal_time, p);
                //// Check collision Plane 3 and if its near emitter than the others.
                plane_normal_time = updateNearPlaneTime(plane3_eq, plane_normal_time, p);
                
                float3 normal = plane_normal_time.xyz;
                float time = plane_normal_time.w;
                
                // There is no collision. Return unmodified parabola.
                if (time == _StartLifeTime){
                    return p;
                }
                
                // Update initial_pos to collision point.
                p.v0 = p.v0 + p.v*time + PARABOLA_COEFFICIENT*p.acc*pow(time, 2);
                // Reflect direction vector.
                p.v = reflect(p.v + p.acc*time, normal);
                // New parabola starts from collision time.
                p.t = p.t - time;
            
                return p;
            }
            
            /**
            * Calc new point position given its id and the current time.
            */
            float3 coneMovement(float3 initial_pos, float id, float time)
            {
                float3 v = getRandomVelocity(id);

                if (v.z < 0.f) v.z = -1 * v.z;
                
                float max_distance_fac = v.z * tan(radians(_ConeAngle));
                v.x = max_distance_fac * v.x;
                v.y = max_distance_fac * v.y;
                // Scale velocity
                v = _StartSpeed * normalize(v);

                // Gravity acceleration modifier.
                float4x4 i_model_rotation = unity_ObjectToWorld;
                i_model_rotation[0][3] = 0.f; // We don't want any translation here:
                i_model_rotation[1][3] = 0.f; // set model transform matrix translation vec to 0.
                i_model_rotation[2][3] = 0.f;
                i_model_rotation[3][3] = 1.f;
                // Apply Model rotation to Gravity.
                v = mul(i_model_rotation, float4(v, 1.f)).xyz;

                float3 acc = float3(0.f, -_GravityModifier, 0.f);
                
                parabola p;
                p.v0  = initial_pos;
                p.v   = v;
                p.acc = acc;
                p.t   = time;
                
                // Set an upper bound to while() loop to prevent while(true).
                int max_collisions = _StartSpeed * _StartLifeTime * _RateOverTime * _GravityModifier;
                while (max_collisions--){
                    // Update parabola for each collision by time.
                    float actual_time = p.t;
                    p = getParabolaAfterCollision(p);
                    if (actual_time == p.t){
                        // No more collision was found.
                        break;
                    }
                }
                
                // Apply Parabola equation: 
                // P(t) = P0 + V0*t + 0.5*Acc*t^2.
                return p.v0 + p.v*p.t + PARABOLA_COEFFICIENT*p.acc*pow(p.t, 2);
            }
            
            /**
            * Given the normal and the center of a plane, 
            * return an Orthonormal Basis.
            */
            basis getPlaneOrthonormalBasis(float3 center, float3 normal)
            {
                float plane_d = -dot(normal, center);
                
                basis b;
                b.b0 = normalize(float3(0.f, 0.f, -(plane_d/normal.z)) - center);
                b.b1 = normalize(cross(b.b0, normal));
                
                return b;
            }
            
            /**
            * Given an center point, calc quad vertex that corresponds to particle uv.
            * Billboard are orthogonal to the Main Camera and has _StartSize lenght.
            */
            float3 getBillboardVertex(float3 quad_center, float2 uv)
            {
                float3 plane_normal = normalize(_WorldSpaceCameraPos - quad_center); 
                float circumradius = _StartSize / 2.f;
                
                // Orthonormal basis vectors of the circle plane.
                basis b = getPlaneOrthonormalBasis(quad_center, plane_normal);

                // Based on uv, use clockwise rule and the basis to draw a square from center_pos.
                float3 v_pos = {0.f,0.f, 0.f};
                
                if(uv.x == 0) {
                    if(uv.y == 0) {
                        v_pos = quad_center - circumradius*b.b1;
                    } else if(uv.y == 1){
                        v_pos = quad_center - circumradius*b.b0;
                    }
                } else if(uv.x == 1) {
                    if(uv.y == 0) {
                        v_pos = quad_center + circumradius*b.b0;
                    } else if(uv.y == 1){
                        v_pos = quad_center + circumradius*b.b1;
                    }
                }
                
                return v_pos;
            }
            
            /**
            * Precalc plane equations to save compute time.
            */
            void setPlaneEquations()
            {
                float3 n; // Normal
                float3 c; // Center
                
                n = normalize(_CollisionPlaneNormal0.xyz);
                c = _CollisionPlaneCenter0.xyz;
                if(n.x != 0.f || n.y != 0.f || n.z != 0.f) {
                    plane0_eq = getPlaneEquation(normalize(n.xyz), c);
                }
                
                n = normalize(_CollisionPlaneNormal1.xyz);
                c = _CollisionPlaneCenter1.xyz;
                if(n.x != 0.f || n.y != 0.f || n.z != 0.f) {
                    plane1_eq = getPlaneEquation(normalize(n.xyz), c);
                }
                
                n = normalize(_CollisionPlaneNormal2.xyz);
                c = _CollisionPlaneCenter2.xyz;
                if(n.x != 0.f || n.y != 0.f || n.z != 0.f) {
                    plane2_eq = getPlaneEquation(normalize(n.xyz), c);
                }
                
                n = normalize(_CollisionPlaneNormal3.xyz);
                c = _CollisionPlaneCenter3.xyz;
                if(n.x != 0.f || n.y != 0.f || n.z != 0.f) {
                    plane3_eq = getPlaneEquation(normalize(n.xyz), c);
                }
            }

            fragmentInput vert (vertexInput v)
            {
                float3 v_pos = v.pos.xyz;
                float4 p_pos = float4(v_pos, 1.f);
                int id = v.id.x;
                
                // _Time.y+1: id starts equal 1 and _Time.y equal 0. We want both starting together.
                float time = _Time.y + 1 - _StartDelay;

                // If a particle doesn't fit upper_bound, all vertices will be equal thus not rasterized.
                float upper_bound = time * _RateOverTime;
                
                if (id <= upper_bound){
                    
                    // Relative time: particles must spawn from time equal zero.
                    float relative_time = time - (id / _RateOverTime);
                    
                    // Relative id to time window to increase randomness.
                    id = id * randomSin(float2(id, id)) * (int)ceil(relative_time / _StartLifeTime);
                    
                    // Normalize relative time.
                    relative_time = relative_time % _StartLifeTime;
                    
                    // Object position coordinates to World coordinates.
                    v_pos = mul(unity_ObjectToWorld, float4(v_pos, 1.f)).xyz;
                    
                    setPlaneEquations();
                    
                    float3 center_pos = float3(0.f, 0.f, 0.f);
                    if (_Shape == 1){
                        center_pos = sphereMovement(v_pos, id, relative_time);
                    } else {
                        // Default shape (Cone)
                        center_pos = coneMovement(v_pos, id, relative_time);
                    }
                    
                    // Get quad center new position (time has changed).
                    // With the center, get quad vertex position based on vertex uv.
                    v_pos = getBillboardVertex(center_pos, v.uv);
                    
                    // View-Projection transformation (Model transformation already been done previously).
                    p_pos = mul(UNITY_MATRIX_VP, float4(v_pos, 1.f));
                }

                fragmentInput o;
                o.pos = p_pos;
                o.uv  = v.uv.xy - fixed2(0.5, 0.5);

                return o;
            }

            fixed4 frag(fragmentInput i) : SV_Target
            {
                // Discard pixels far from quad center: draw circle.
                float distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                if (distance > 0.4f)
                   discard;
                
                float alpha = 1.f - 2.5*distance;
                
                return fixed4(_StartColor.xyz, alpha);
            }

            ENDCG
        }
    }
}