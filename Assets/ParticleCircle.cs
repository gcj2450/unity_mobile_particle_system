﻿using System.Collections.Generic;
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
            
            MeshFilter mf = particles[i].GetComponent<MeshFilter>();

            var mesh = new Mesh();
            mf.mesh = mesh;
    
            //@TODO find orthogonal plan from camera and get their vertices.
            Vector3[] vertices = new Vector3[4];
            vertices[0] = new Vector3(emitterPosition.x-particleSize, emitterPosition.y-particleSize, 0);
            vertices[1] = new Vector3(emitterPosition.x+particleSize, emitterPosition.y-particleSize, 0);
            vertices[2] = new Vector3(emitterPosition.x-particleSize, emitterPosition.y+particleSize, 0);
            vertices[3] = new Vector3(emitterPosition.x+particleSize, emitterPosition.y+particleSize, 0);
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
            
            // Passing ID and Time as UV2.
            // @TODO improve this!
            Vector2[] id = new Vector2[4];
            id[0] = new Vector2(i, 0);
            id[1] = new Vector2(i, 0);
            id[2] = new Vector2(i, 0);
            id[3] = new Vector2(i, 0);
            mesh.uv2 = id;
        }
    }

    public void Update()
    {
        totalTime += Time.deltaTime;
        for(int i = 0; i < totalParticles; i++) {
            MeshFilter mf = particles[i].GetComponent<MeshFilter>();
            Vector2[] id = new Vector2[4];
            id[0] = new Vector2(i, totalTime);
            id[1] = new Vector2(i, totalTime);
            id[2] = new Vector2(i, totalTime);
            id[3] = new Vector2(i, totalTime);

            mf.mesh.uv2 = id;
        }

        if (totalTime >= lifeTimeInSeconds) {
            for (int i = 0; i < totalParticles; i++) {
                Destroy(particles[i]);
            }
            if (respawn){
                Start();
            }
        }
    }
}