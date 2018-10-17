using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class ParticleCircle : MonoBehaviour
{
    public float particleDuration     = 5.0f;
    public float particleSize         = 1.0f;
    public float particleSpeedScale   = 10.0f;
    public int maxParticles           = 200;
    
    private float totalTime           = 0;

    [System.Serializable]
    public struct Emission
    {
        public float rateOverTime;
    }

    public Emission emission;
    
    public enum ShapeType{ Cone, Sphere }

    public ShapeType shape;

    [System.Serializable]
    public struct Cone
    {
        public float angle;
        public float radius;   
    }
    public Cone cone;
    
    [System.Serializable]
    public struct Sphere
    {
        public float angle;
    }
    public Sphere sphere;
    
    private void setMeshes()
    {
        Vector3[] vertices = new Vector3[4*maxParticles];
        int    [] tri      = new int    [6*maxParticles];
        Vector2[] uv       = new Vector2[4*maxParticles];
        Vector2[] id       = new Vector2[4*maxParticles];

        for (int i = 0; i < maxParticles; i++)
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
        if (renderer.sharedMaterial.GetFloat("_ParticleSize") != particleSize){
            renderer.sharedMaterial.SetFloat("_ParticleSize", particleSize);
        }
        if (renderer.sharedMaterial.GetFloat("_ParticleRateOverTime") != emission.rateOverTime){
            renderer.sharedMaterial.SetFloat("_ParticleRateOverTime", emission.rateOverTime);
        }
        if (renderer.sharedMaterial.GetFloat("_ParticleSpeedScale") != particleSpeedScale){
            renderer.sharedMaterial.SetFloat("_ParticleSpeedScale", particleSpeedScale);
        }
        if (renderer.sharedMaterial.GetInt("_ParticleShape") != (int)shape){
            renderer.sharedMaterial.SetFloat("_ParticleShape", (int)shape);
        }
        if (renderer.sharedMaterial.GetInt("_MaxParticles") != maxParticles){
            renderer.sharedMaterial.SetInt("_MaxParticles", maxParticles);
        }
        if (renderer.sharedMaterial.GetFloat("_ParticleDuration") != particleDuration){
            renderer.sharedMaterial.SetFloat("_ParticleDuration", particleDuration);
        }
        
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (maxParticles != mesh.vertexCount*4){
            setMeshes();
        }
        
        totalTime += Time.deltaTime;
        //if (totalTime >= lifeTimeInSeconds){
        //    //@TODO KILL EMITTER
        //}
    }
}