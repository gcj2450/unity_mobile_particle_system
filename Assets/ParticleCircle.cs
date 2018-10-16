using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class ParticleCircle : MonoBehaviour
{
    public Vector3 emitterPosition      = Vector3.zero;
    public float particleSize           = 0.05f;
    public float particleSpeedScale     = 10.0f;
    public int totalParticles           = 200;
    public int lifeTimeInSeconds        = 10;

    private float totalTime             = 0;
    
    private void setMeshes()
    {
        Vector3[] vertices = new Vector3[4*totalParticles];
        int    [] tri      = new int    [6*totalParticles];
        Vector2[] uv       = new Vector2[4*totalParticles];
        Vector2[] id       = new Vector2[4*totalParticles];

        for (int i = 0; i < totalParticles; i++)
        {
            int idx4 = i * 4;
            int index6 = i * 6;

            vertices[idx4 + 0] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[idx4 + 1] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[idx4 + 2] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
            vertices[idx4 + 3] = new Vector3(emitterPosition.x, emitterPosition.y, emitterPosition.z);
    
            tri[index6 + 0] = idx4 + 0;
            tri[index6 + 1] = idx4 + 2;
            tri[index6 + 2] = idx4 + 1;
            tri[index6 + 3] = idx4 + 2;
            tri[index6 + 4] = idx4 + 3;
            tri[index6 + 5] = idx4 + 1;
    
            uv[idx4 + 0] = new Vector2(0, 0);
            uv[idx4 + 1] = new Vector2(1, 0);
            uv[idx4 + 2] = new Vector2(0, 1);
            uv[idx4 + 3] = new Vector2(1, 1);
            
            // Passing ID as UV2.
            id[idx4 + 0] = new Vector2(i+1, 0);
            id[idx4 + 1] = new Vector2(i+1, 0);
            id[idx4 + 2] = new Vector2(i+1, 0);
            id[idx4 + 3] = new Vector2(i+1, 0);
        }

        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        mesh.Clear();
        
        mesh.vertices   = vertices;
        mesh.triangles  = tri;
        mesh.uv         = uv;
        mesh.uv2        = id;   
    }
    
    void Awake()
    {
        totalTime = 0f;
        EditorApplication.update = Update;
        Debug.Log("Editor causes this Awake");
        
        Shader shader = Shader.Find("Unlit/ParticleCircle");

        Renderer renderer = GetComponent<Renderer>();
        renderer.sharedMaterial.shader = shader;
        renderer.sharedMaterial.SetFloat("_ParticleSize", particleSize);
        renderer.sharedMaterial.SetFloat("_ParticleSpeedScale", particleSpeedScale);

        setMeshes();
    }

    public void Update()
    {
        EditorUtility.SetDirty(this);

        totalTime += Time.deltaTime;
       
        if (totalTime >= lifeTimeInSeconds) {
            Awake();
        }
    }
}