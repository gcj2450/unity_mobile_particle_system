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

        _CollisionPlaneEquation0("Collision Plane Equation 0", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneEquation1("Collision Plane Equation 1", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneEquation2("Collision Plane Equation 2", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CollisionPlaneEquation3("Collision Plane Equation 3", Vector) = (0.0, 0.0, 0.0, 0.0)
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

            uniform fixed _StartSize = 1.0f;
            uniform fixed _RateOverTime = 10.f;
            uniform fixed _StartSpeed = 5.f;
            uniform fixed _StartLifeTime = 5.f;
            uniform fixed _StartDelay = 0.f;
            uniform fixed _GravityModifier = 0.0f;

            uniform fixed4 _StartColor = fixed4(0.f, 0.f, 0.f, 1.f);

            uniform int   _Shape = 0;
            uniform fixed _ConeAngle = 0.f;

            uniform fixed4 _CollisionPlaneEquation0 = fixed4(0.f, 0.f, 0.f, 0.f);
            uniform fixed4 _CollisionPlaneEquation1 = fixed4(0.f, 0.f, 0.f, 0.f);
            uniform fixed4 _CollisionPlaneEquation2 = fixed4(0.f, 0.f, 0.f, 0.f);
            uniform fixed4 _CollisionPlaneEquation3 = fixed4(0.f, 0.f, 0.f, 0.f);
 
            static const fixed  HASHSCALE1 = 0.1031;
            static const fixed3 HASHSCALE3 = fixed3(.1031, .1030, .0973);
            static const fixed  ITERATIONS = 4.f;
            static const fixed  GRAVITY_COEFF = 4.f;
            static const fixed3 GRAVITY_VEC = fixed3(0.f, -_GravityModifier, 0.f);
            
            struct fragmentInput {
                fixed4 pos    : SV_POSITION;
                fixed2 uv     : TEXCOORD0;
                fixed3 normal : NORMAL;
            };
            
            struct vertexInput {
                fixed4 pos : POSITION;
                fixed2 id  : TEXCOORD2;
                fixed2 uv  : TEXCOORD0;
            };
            
            struct basis {
                fixed3 b0;
                fixed3 b1;
            };
            
            struct parabola {
                fixed3 v0;
                fixed3 v;
                fixed  t;
                fixed3 acc;
                bool final;
            };
            
            // Hash functions to generate entropy by David Hoskins
            // https://www.shadertoy.com/view/4djSRW
            fixed hash11(fixed p)
            {
                fixed frac_p = frac(p);
                fixed3 p3 = fixed3(frac_p, frac_p, frac_p) * HASHSCALE1;
                p3 += dot(p3, p3.yzx + 19.19);
               
                return frac((p3.x + p3.y) * p3.z);
            }
            
            fixed3 hash31(fixed p) 
            {
                fixed3 p3 = frac(fixed3(p, p, p) * HASHSCALE3);
                p3 += dot(p3, p3.yzx+19.19);
               
                return frac((p3.xxy + p3.yzz)*p3.zyx); 
            }
            
            fixed randomSin(fixed2 _st)
            {
                return frac(sin(dot(_st.xy, fixed2(12.9898f,78.233f)))*43758.5453123f);
            }
            
            // Calc initial velocity/direction to a particle given its id.
            // Return an fixed3 vec. Elements range: (0 <= p <= 1)
            // >>> This number will be the same for each particle, in all frames. <<<
            fixed3 getRandomVelocity(fixed id)
            {
                fixed3 v = fixed3(0.f, 0.f, 0.f);
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
            fixed2 solveQuadraticEquation(fixed3 coefficients)
            {
                fixed delta = pow(coefficients[1], 2) - 4*coefficients[0]*coefficients[2];
    
                if (delta < 0){
                    return fixed2(-1, -1);
                }

                fixed2 sol;
                sol[0] = (-coefficients[1] + sqrt(delta)) / (2*coefficients[0]);
                sol[1] = (-coefficients[1] - sqrt(delta)) / (2*coefficients[0]);

                return sol;
            }
            
            /**
            * Returns the time at which the intersection between plane and parabola occurs.
            * If return is < 0 there is no intersection.
            */
            fixed getCollisionTime(fixed4 plane_equation, parabola p)
            {
                fixed a = dot(plane_equation.xyz, GRAVITY_VEC) * GRAVITY_COEFF;
                fixed b = dot(plane_equation.xyz, p.v);
                fixed c = dot(plane_equation.xyz, p.v0) + plane_equation.w;
                
                if (a != 0.f){
                    // Has acceleration => quadratic
                    fixed2 time = solveQuadraticEquation(fixed3(a, b, c));
                    if (time[0] >= 0.f){
                        return time[0];
                    }
                    return time[1];
                } else {
                    // No acceleration => linear
                    return -c/b;
                }
            }
            
            /**
            * Return updated fixed4(normal.x, normal.y, normal.z, lower_time) if has collision in lower time.
            */
            fixed4 updateNearPlaneTime(fixed4 plane_equation, fixed4 lower_plane_normal_time, const parabola p)
            {
                const fixed time_threshold = 0.01f;

                fixed plane_collision_time = getCollisionTime(plane_equation, p);
                //plane_collision_time = plane_collision_time - (_StartSize/ 8);
                
                // time_threshold prevents the particle go through the plane.
                if (plane_collision_time > time_threshold){
                    // actual time must be greater than collision time.
                    if (p.t > plane_collision_time){
                        // check if collision time found this plane is lower than that found with other planes.
                        if (plane_collision_time < lower_plane_normal_time.w){
                            // particle collision time outside plane.
                            plane_collision_time = plane_collision_time - time_threshold;
                            // set lower_plane_normal_time with lower time and plane normal.
                            lower_plane_normal_time = fixed4(plane_equation.xyz, plane_collision_time);
                        }
                    }
                }
                
                return lower_plane_normal_time;
            }
            
            /**
            * Given an initial parabola return new parabola after plane collisions.
            */
            parabola getNextParabolaAfterCollision(parabola p)
            {
                fixed4 plane_normal_time = fixed4(0.f, 0.f, 0.f, _StartLifeTime);
                
                // Check collision Plane 0 and if its near emitter than the others.
                if (_CollisionPlaneEquation0.x != 0.f || _CollisionPlaneEquation0.y != 0 || _CollisionPlaneEquation0.z != 0){
                    plane_normal_time = updateNearPlaneTime(_CollisionPlaneEquation0, plane_normal_time, p);
                }
                // Check collision Plane 1 and if its near emitter than the others.
                if (_CollisionPlaneEquation1.x != 0.f || _CollisionPlaneEquation1.y != 0 || _CollisionPlaneEquation1.z != 0){
                    plane_normal_time = updateNearPlaneTime(_CollisionPlaneEquation1, plane_normal_time, p);
                }
                // Check collision Plane 2 and if its near emitter than the others.
                if (_CollisionPlaneEquation2.x != 0.f || _CollisionPlaneEquation2.y != 0 || _CollisionPlaneEquation2.z != 0){
                    plane_normal_time = updateNearPlaneTime(_CollisionPlaneEquation2, plane_normal_time, p);
                }
                // Check collision Plane 3 and if its near emitter than the others.
                if (_CollisionPlaneEquation3.x != 0.f || _CollisionPlaneEquation3.y != 0 || _CollisionPlaneEquation3.z != 0){
                    plane_normal_time = updateNearPlaneTime(_CollisionPlaneEquation3, plane_normal_time, p);
                }
                
                // Get normal and collision time of the nearest plane.
                fixed3 normal = plane_normal_time.xyz;
                fixed time = plane_normal_time.w;
                
                // There is no collision. Return unmodified parabola.
                if (time == _StartLifeTime){
                    p.final = true;
                    return p;
                }
                
                fixed3 g = (GRAVITY_COEFF*pow(time, 2)) * GRAVITY_VEC;

                // Update initial_pos to collision point.
                p.v0 = p.v0 + p.v*time + g;
                // Reflect direction vector.
                p.v = reflect(p.v + GRAVITY_VEC*time, normal);
                // New parabola starts from collision time.
                p.t = p.t - time;
                
                if (time <= 0.1f){
                    // Time doesn't changed that much => particle is rolling.
                    // Update gravity.
                    g = (GRAVITY_COEFF*pow(p.t, 2)) * GRAVITY_VEC;
                    // Project vector g+v onto plane.
                    fixed3 u = g + p.v;
                    fixed3 proj_uN = normalize(normal) * (dot(u, normal) / length(normal));
                    p.v = u - proj_uN;
                    p.final = true;
                    // Ignore gravity (already calc result force vec).
                    p.acc = 0.f;
                }
            
                return p;
            }
            
            /**
            * Given a parabola return particle position after calc collisions.
            */
            fixed3 getParticlePosition(parabola p)
            {
                // Set an upper bound to while() loop to prevent while(true).
                int max_collisions = _StartSpeed * _StartLifeTime * _RateOverTime;
                // Iterate updating parabola until there's no more collisions.
                while (max_collisions--){
                    fixed actual_time = p.t;
                    // Update parabola for each collision by time.
                    p = getNextParabolaAfterCollision(p);
                    if (p.final){
                        // Parabola will not change. Stop iteration.
                        break;
                    }
                }
                
                // Apply Parabola equation: 
                // P(t) = P0 + V0*t + 0.5*Acc*t^2.
                fixed3 g = (GRAVITY_COEFF*pow(p.t, 2)) * p.acc;
                return p.v0 + p.v*p.t + g;
            }
            
            /**
            * Apply unity_ObjectToWorld transf matrix with no translations.
            */
            fixed3 objctToWorldNoTranslation(fixed3 v)
            {
                fixed4x4 i_model_rotation = unity_ObjectToWorld;
                i_model_rotation[0][3] = 0.f; // Prevent translation:
                i_model_rotation[1][3] = 0.f; // set model transform matrix translation vec to 0.
                i_model_rotation[2][3] = 0.f;
                
                return mul(i_model_rotation, fixed4(v, 1.f)).xyz;
            }
            
            /**
            * Calc new point position given its id and the current time.
            */
            fixed3 sphereMovement(fixed3 initial_pos, fixed id, fixed time)
            {
                fixed3 v = getRandomVelocity(id);

                // Scale velocity
                v = _StartSpeed * v;
                
                v = objctToWorldNoTranslation(v);
                                
                parabola p;
                p.v0    = initial_pos;
                p.v     = v;
                p.t     = time;
                p.acc   = GRAVITY_VEC;
                p.final = false;
                
                return getParticlePosition(p);
            }
            
            /**
            * Calc new point position given its id and the current time.
            */
            fixed3 coneMovement(fixed3 initial_pos, fixed id, fixed time)
            {
                fixed3 v = getRandomVelocity(id);

                // Cone coordinates transformations.
                if (v.z < 0.f) v.z = -1 * v.z;
                fixed max_distance_fac = v.z * tan(radians(_ConeAngle));
                v.x = max_distance_fac * v.x;
                v.y = max_distance_fac * v.y;
                
                // Scale velocity
                v = _StartSpeed * normalize(v);

                v = objctToWorldNoTranslation(v);

                parabola p;
                p.v0    = initial_pos;
                p.v     = v;
                p.t     = time;
                p.acc   = GRAVITY_VEC;
                p.final = false;
                
                return getParticlePosition(p);
            }
            
            /**
            * Given the normal and the center of a plane, 
            * return an Orthonormal Basis.
            */
            basis getPlaneOrthonormalBasis(fixed3 center, fixed3 normal)
            {
                fixed plane_d = -dot(normal, center);
                
                basis b;
                b.b0 = normalize(fixed3(0.f, 0.f, -(plane_d/normal.z)) - center);
                b.b1 = normalize(cross(b.b0, normal));
                
                return b;
            }
            
            /**
            * Given an center point, calc quad vertex that corresponds to particle uv.
            * Billboard are orthogonal to the Main Camera and has _StartSize lenght.
            */
            fixed3 getBillboardVertex(fixed3 quad_center, fixed2 uv)
            {
                fixed3 plane_normal = normalize(_WorldSpaceCameraPos - quad_center); 
                fixed circumradius = _StartSize / 2.f;
                
                // Orthonormal basis vectors of the circle plane.
                basis b = getPlaneOrthonormalBasis(quad_center, plane_normal);

                // Based on uv, use clockwise rule and the basis to draw a square from center_pos.
                fixed3 v_pos = {0.f,0.f, 0.f};
                
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

            fragmentInput vert (vertexInput v)
            {
                fixed3 v_pos = v.pos.xyz;
                fixed4 p_pos = fixed4(v_pos, 1.f);
                int id = v.id.x;
                
                // _Time.y+1: id starts equal 1 and _Time.y equal 0. We want both starting together.
                fixed time = _Time.y + 1 - _StartDelay;

                // If a particle doesn't fit upper_bound, all vertices will be equal thus not rasterized.
                fixed upper_bound = time * _RateOverTime;
                
                if (id <= upper_bound){
                    
                    // Relative time: particles must spawn from time equal zero.
                    fixed relative_time = time - (id / _RateOverTime);
                    
                    // Relative id to time window to increase randomness.
                    id = id * randomSin(fixed2(id, id)) * (int)ceil(relative_time / _StartLifeTime);
                    
                    // Normalize relative time.
                    relative_time = relative_time % _StartLifeTime;
                    
                    // Object position coordinates to World coordinates.
                    v_pos = mul(unity_ObjectToWorld, fixed4(v_pos, 1.f)).xyz;
                     
                    fixed3 center_pos = fixed3(0.f, 0.f, 0.f);
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
                    p_pos = mul(UNITY_MATRIX_VP, fixed4(v_pos, 1.f));
                }

                fragmentInput o;
                o.pos = p_pos;
                o.uv  = v.uv.xy - fixed2(0.5, 0.5);

                return o;
            }

            fixed4 frag(fragmentInput i) : SV_Target
            {
                // Discard pixels far from quad center: draw circle.
                fixed distance = sqrt(pow(i.uv.x, 2) + pow(i.uv.y, 2));
                if (distance > 0.4f)
                    discard;
                
                fixed alpha = 1.f - 2.5*distance;
                
                return fixed4(_StartColor.xyz, alpha);
            }

            ENDCG
        }
    }
}