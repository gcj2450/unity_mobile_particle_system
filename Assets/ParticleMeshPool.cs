using System.Collections.Generic;
using UnityEngine;
using Random = System.Random;

public static class ParticleMeshPool
{
    public static int MAX_PARTICLES = 1000000;
    private static List<ParticleMesh> pool = new List<ParticleMesh>();
    
    public static ParticleMesh[] GetParticleMeshes(int size)
    {
        allocateParticles();

        if (size > MAX_PARTICLES) size = MAX_PARTICLES;
        
        return pool.GetRange(0, size-1).ToArray();
    }
    
    public static void allocateParticles()
    {
        if (pool.Count == 0) {

            Vector3 emitter_pos = new Vector3(0,0,0);

            Vector2[] uv = new Vector2[4];
            uv[0] = new Vector2(0, 0);
            uv[1] = new Vector2(1, 0);
            uv[2] = new Vector2(0, 1);
            uv[3] = new Vector2(1, 1);
            
            Vector3[] ver = new Vector3[4];
            ver[0] = emitter_pos;
            ver[1] = emitter_pos;
            ver[2] = emitter_pos;
            ver[3] = emitter_pos;
            
            for (int i = 0; i < MAX_PARTICLES; i++){
                
                ParticleMesh p = new ParticleMesh();
                
                int idx4 = i * 4;
                p.tri    = new int[6];
                p.tri[0] = idx4 + 0;
                p.tri[1] = idx4 + 2;
                p.tri[2] = idx4 + 1;
                p.tri[3] = idx4 + 2;
                p.tri[4] = idx4 + 3;
                p.tri[5] = idx4 + 1;
    
                // Passing ID as UV2.
                Vector2 id_val = new Vector2(i + 1, 0);
                p.id    = new Vector2[4];
                p.id[0] = id_val;
                p.id[1] = id_val;
                p.id[2] = id_val;
                p.id[3] = id_val;
                
                p.ver    = ver;
                p.uv     = uv;
                p.in_use = false;
                
                pool.Add(p);
            }
        }
    }

}
