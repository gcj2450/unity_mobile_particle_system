using System.Collections.Generic;
using UnityEngine;

public class ParticleCircle : MonoBehaviour
{
    [System.Serializable]
    public struct Position
    {
        public int x;
        public int y;
        public int z;
    }
    
    public Position emitterPosition;
    public float particleSize           = 0.05f;
    public float particleSpeedScale     = 10.0f;
    public int totalParticles           = 2000;
    public int lifeTimeInSeconds        = 10;
    public bool respawn                 = false;

    private float totalTime;
    private  List<GameObject> particles;
    
    public void Start()
    {
        Shader shader = Shader.Find("Unlit/ParticleCircle");

        particles = new List<GameObject>();
        totalTime = 0f;
            
        for (int i = 0; i < totalParticles; i++)
        {
            particles.Add(GameObject.CreatePrimitive(PrimitiveType.Quad));
            
            Renderer renderer = particles[i].GetComponent<Renderer>();
            renderer.material.shader = shader;
            renderer.material.SetFloat("_ParticleSize", particleSize);
            renderer.material.SetFloat("_ParticleSpeedScale", particleSpeedScale);
            
            MeshFilter mf = particles[i].GetComponent<MeshFilter>();

            var mesh = new Mesh();
            mf.mesh = mesh;
    
            Vector3[] vertices = new Vector3[4];
            vertices[0] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[1] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[2] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[3] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            mesh.vertices = vertices;
    
            int[] tri = new int[6];
            tri[0] = 0;
            tri[1] = 2;
            tri[2] = 1;
            tri[3] = 2;
            tri[4] = 3;
            tri[5] = 1;
            mesh.triangles = tri;
    
            Vector2[] uv = new Vector2[4];
            uv[0] = new Vector2(0, 0);
            uv[1] = new Vector2(1, 0);
            uv[2] = new Vector2(0, 1);
            uv[3] = new Vector2(1, 1);
            mesh.uv = uv;

            float mesh_id = 4*i + 1;
            float time = 0f;
            
            // Passing ID and Time as UV2.
            Vector2[] id_time = new Vector2[4];
            id_time[0] = new Vector2(mesh_id, time);
            id_time[1] = new Vector2(mesh_id+1, time);
            id_time[2] = new Vector2(mesh_id+2, time);
            id_time[3] = new Vector2(mesh_id+3, time);
            mesh.uv2 = id_time;
        }
    }

    public void Update()
    {
        totalTime += Time.deltaTime;
        for(int i = 0; i < totalParticles; i++) {

            MeshFilter mf = particles[i].GetComponent<MeshFilter>();
            
            Vector2[] id = new Vector2[4];
            id[0] = new Vector2(mf.mesh.uv2[0].x, totalTime);
            id[1] = new Vector2(mf.mesh.uv2[1].x, totalTime);
            id[2] = new Vector2(mf.mesh.uv2[2].x, totalTime);
            id[3] = new Vector2(mf.mesh.uv2[3].x, totalTime);

            mf.mesh.uv2 = id;
        }

        if (totalTime >= lifeTimeInSeconds) {
            for (int i = 0; i < totalParticles; i++) 
                Destroy(particles[i]);
            particles.Clear();
            
            if (respawn) Start();
        }
    }
}