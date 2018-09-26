using UnityEngine;

public class Line : MonoBehaviour
{
    
    public float size;

    public int x;
    public int y;
    public int z;

    public int totalParticles;

    public void Start() 
    {
        Shader shader = Shader.Find("Unlit/Line");
        
        for (int i = 0; i < totalParticles; i++)
        {
            GameObject quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            Renderer renderer = quad.GetComponent<Renderer>();
            renderer.material.shader = shader;
            
            MeshFilter mf = quad.GetComponent<MeshFilter>();

            var mesh = new Mesh();
            mf.mesh = mesh;
    
            Vector3[] vertices = new Vector3[4];
    
            vertices[0] = new Vector3(i, i, 0);
            vertices[1] = new Vector3(size, i, 0);
            vertices[2] = new Vector3(i, size, 0);
            vertices[3] = new Vector3(size, size, 0);
    
            mesh.vertices = vertices;
    
            int[] tri= new int[6];

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
        }
    }
}