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
    public int totalParticles           = 200;
    public int lifeTimeInSeconds        = 10;
    public bool respawn                 = false;

    private GameObject particles;

    private float totalTime;

    public void Start()
    {
        totalTime = 0f;

        Shader shader = Shader.Find("Unlit/ParticleCircle");

        particles = GameObject.CreatePrimitive(PrimitiveType.Quad);
        
        Renderer renderer = particles.GetComponent<Renderer>();
        renderer.material.shader = shader;
        renderer.material.SetFloat("_ParticleSize", particleSize);
        renderer.material.SetFloat("_ParticleSpeedScale", particleSpeedScale);

        Vector3[] vertices = new Vector3[4*totalParticles];
        int[]     tri      = new int[6*totalParticles];
        Vector2[] uv       = new Vector2[4*totalParticles];
        Vector2[] id_time  = new Vector2[4*totalParticles];

        for (int i = 0; i < totalParticles; i++)
        {
            vertices[i*4 + 0] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[i*4 + 1] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[i*4 + 2] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[i*4 + 3] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
    
            tri[i*6 + 0] = i*4 + 0;
            tri[i*6 + 1] = i*4 + 2;
            tri[i*6 + 2] = i*4 + 1;
            tri[i*6 + 3] = i*4 + 2;
            tri[i*6 + 4] = i*4 + 3;
            tri[i*6 + 5] = i*4 + 1;
    
            uv[i*4 + 0] = new Vector2(0, 0);
            uv[i*4 + 1] = new Vector2(1, 0);
            uv[i*4 + 2] = new Vector2(0, 1);
            uv[i*4 + 3] = new Vector2(1, 1);
            
            // Passing ID and Initial Time as UV2.
            id_time[i*4 + 0] = new Vector2(i+1, 0);
            id_time[i*4 + 1] = new Vector2(i+1, 0);
            id_time[i*4 + 2] = new Vector2(i+1, 0);
            id_time[i*4 + 3] = new Vector2(i+1, 0);
        }

        Mesh mesh = new Mesh();
        mesh.vertices   = vertices;
        mesh.triangles  = tri;
        mesh.uv         = uv;
        mesh.uv2        = id_time;
        
        particles.GetComponent<MeshFilter>().mesh = mesh;
    }

    public void Update()
    {
        totalTime += Time.deltaTime;
        MeshFilter mf = particles.GetComponent<MeshFilter>();

        Vector2[] id_time = new Vector2[4*totalParticles];
        for(int i = 0; i < totalParticles; i++) {
            id_time[i*4 + 0] = new Vector2(mf.mesh.uv2[i*4 + 0].x, totalTime);
            id_time[i*4 + 1] = new Vector2(mf.mesh.uv2[i*4 + 1].x, totalTime);
            id_time[i*4 + 2] = new Vector2(mf.mesh.uv2[i*4 + 2].x, totalTime);
            id_time[i*4 + 3] = new Vector2(mf.mesh.uv2[i*4 + 3].x, totalTime);
        }

        mf.mesh.uv2 = id_time;

        if (totalTime >= lifeTimeInSeconds) {
            if (respawn) Start();
        }
    }
}