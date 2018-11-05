using System.Collections.Generic;
using UnityEngine;
using Random = System.Random;

public class ParticleMeshPool
{
    private static List<ParticleMesh> pool = new List<ParticleMesh>();
    
    public static ParticleMesh getParticleMesh()
    {
        allocateParticles();
        
        for (int i = 0; i < pool.Count; i++){
            if (!pool[i].in_use) {
                return pool[i];
            }
        }
        
        Random rnd = new Random();
        int idx = rnd.Next(0, pool.Count-1);

        return pool[idx];
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
            
            for (int i = 0; i < 10000; i++){
                
                ParticleMesh p = new ParticleMesh();
                
                p.tri    = new int[6];
                p.id     = new Vector2[4];
                p.ver    = ver;
                p.uv     = uv;
                p.in_use = false;
                
                pool.Add(p);
            }
        }
    }

}
