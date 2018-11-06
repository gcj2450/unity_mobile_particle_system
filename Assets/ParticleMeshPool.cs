using UnityEngine;

public static class ParticleMeshPool
{
    public static int MAX_PARTICLES = 1000000;
    private static ParticleMesh pool;
    
    public static ParticleMesh GetParticleMeshes()
    {
        allocateParticles();
        return pool;
    }
    
    public static void allocateParticles()
    {
        if (pool == null) {

            pool = new ParticleMesh();

            Vector3 pos = new Vector3(0, 0, 0);
            pool.pos = new Vector3[4 * MAX_PARTICLES];
            pool.uv  = new Vector2[4 * MAX_PARTICLES];
            pool.tri = new int    [6 * MAX_PARTICLES];
            pool.id  = new Vector2[4 * MAX_PARTICLES];

            for (int i = 0; i < MAX_PARTICLES; i++){
                
                int idx4 = i * 4;
                int idx6 = i * 6;
                
                pool.pos[idx4 + 0] = pos;
                pool.pos[idx4 + 1] = pos;
                pool.pos[idx4 + 2] = pos;
                pool.pos[idx4 + 3] = pos;

                pool.uv[idx4 + 0] = new Vector2(0, 0);
                pool.uv[idx4 + 1] = new Vector2(1, 0);
                pool.uv[idx4 + 2] = new Vector2(0, 1);
                pool.uv[idx4 + 3] = new Vector2(1, 1);
                
                pool.tri[idx6 + 0] = idx4 + 0;
                pool.tri[idx6 + 1] = idx4 + 2;
                pool.tri[idx6 + 2] = idx4 + 1;
                pool.tri[idx6 + 3] = idx4 + 2;
                pool.tri[idx6 + 4] = idx4 + 3;
                pool.tri[idx6 + 5] = idx4 + 1;
    
                // Passing ID as UV2.
                Vector2 id_val = new Vector2(i + 1, 0);
                pool.id[idx4 + 0] = id_val;
                pool.id[idx4 + 1] = id_val;
                pool.id[idx4 + 2] = id_val;
                pool.id[idx4 + 3] = id_val;
            }
        }
    }

}
