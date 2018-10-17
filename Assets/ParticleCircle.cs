using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class ParticleCircle : MonoBehaviour
{
    public float particleSize         = 0.05f;
    public float particleSpeedScale   = 10.0f;
    public int totalParticles         = 200;
    public int lifeTimeInSeconds      = 10;
    
    private float totalTime           = 0;

    public enum ShapeType{ Cone, Sphere }

    public ShapeType shape;

    [System.Serializable]
    public struct Cone
    {
        public float     angle;
        public float     radius;   
    }
    public Cone cone;
    
    [System.Serializable]
    public struct Sphere
    {
        public float     angle;
    }
    public Sphere sphere;
    
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

            vertices[idx4 + 0] = Vector3.zero;
            vertices[idx4 + 1] = Vector3.zero;
            vertices[idx4 + 2] = Vector3.zero;
            vertices[idx4 + 3] = Vector3.zero;
    
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
        EditorApplication.update = TriggerUpdate;
        
        Shader shader = Shader.Find("Unlit/ParticleCircle");

        Renderer renderer = GetComponent<Renderer>();
        renderer.sharedMaterial.shader = shader;

        setMeshes();
    }

    public void TriggerUpdate()
    {
        EditorUtility.SetDirty(this);
    }

    public void Update()
    {
        Renderer renderer = GetComponent<Renderer>();
        if (!Mathf.Approximately(renderer.sharedMaterial.GetFloat("_ParticleSize"), particleSize)){
            renderer.sharedMaterial.SetFloat("_ParticleSize", particleSize);
        }
        if (renderer.sharedMaterial.GetInt("_ParticleLifeTime") != lifeTimeInSeconds){
            renderer.sharedMaterial.SetFloat("_ParticleLifeTime", lifeTimeInSeconds);
        }
        if (!Mathf.Approximately(renderer.sharedMaterial.GetFloat("_ParticleSpeedScale"), particleSpeedScale)){
            renderer.sharedMaterial.SetFloat("_ParticleSpeedScale", particleSpeedScale);
        }
        
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (totalParticles != mesh.vertexCount*4){
            setMeshes();
        }
        
        totalTime += Time.deltaTime;
        if (totalTime >= lifeTimeInSeconds){
            //@TODO KILL EMITTER
        }
    }
}