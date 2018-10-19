using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class ParticleCircle : MonoBehaviour
{
    public float startDelay     = 0.0f;
    public float startLifetime  = 5.0f;
    public float startSpeed     = 10.0f;
    public float startSize      = 1.0f;
    public int   maxParticles   = 200;
    
    private float totalTime     = 0;

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
    }
    public Cone cone;
    
    [System.Serializable]
    public struct Sphere
    {
        public float radius;
    }
    public Sphere sphere;
    
    private void setMeshes()
    {
        int max_p = (int)Mathf.Ceil(startLifetime*emission.rateOverTime);
        if (max_p > maxParticles){
            max_p = maxParticles;
        }
        
        Vector3[] vertices = new Vector3[4*max_p];
        int    [] tri      = new int    [6*max_p];
        Vector2[] uv       = new Vector2[4*max_p];
        Vector2[] id       = new Vector2[4*max_p];

        Vector3 emitter_pos = gameObject.transform.position;

        for (int i = 0; i < max_p; i++)
        {
            int idx4 = i * 4;
            int index6 = i * 6;

            vertices[idx4 + 0] = emitter_pos;
            vertices[idx4 + 1] = emitter_pos;
            vertices[idx4 + 2] = emitter_pos;
            vertices[idx4 + 3] = emitter_pos;
    
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
        
        //@TODO Interface to set bounds -> particle render out clipping space.
        //mesh.bounds     = new Bounds(emitter_pos, new Vector3(100, 100, 100));
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

#if UNITY_EDITOR
        Renderer renderer = GetComponent<Renderer>();
        if (renderer.sharedMaterial.GetFloat("_StartSize") != startSize){
            renderer.sharedMaterial.SetFloat("_StartSize", startSize);
        }
        if (renderer.sharedMaterial.GetFloat("_RateOverTime") != emission.rateOverTime){
            renderer.sharedMaterial.SetFloat("_RateOverTime", emission.rateOverTime);
        }
        if (renderer.sharedMaterial.GetFloat("_StartSpeed") != startSpeed){
            renderer.sharedMaterial.SetFloat("_StartSpeed", startSpeed);
        }
        if (renderer.sharedMaterial.GetFloat("_StartLifeTime") != startLifetime){
            renderer.sharedMaterial.SetFloat("_StartLifeTime", startLifetime);
        }
        if (renderer.sharedMaterial.GetFloat("_StartDelay") != startDelay){
            renderer.sharedMaterial.SetFloat("_StartDelay", startDelay);
        }
        if (renderer.sharedMaterial.GetInt("_Shape") != (int)shape){
            renderer.sharedMaterial.SetInt("_Shape", (int)shape);
        }
        if (renderer.sharedMaterial.GetFloat("_ConeAngle") != cone.angle){
            renderer.sharedMaterial.SetFloat("_ConeAngle", cone.angle);
        }
        
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (maxParticles != (mesh.vertexCount*4)){
            setMeshes();
        }
#endif
        
        totalTime += Time.deltaTime;
        //if (totalTime >= lifeTimeInSeconds){
        //    //@TODO KILL EMITTER
        //}
    }
}