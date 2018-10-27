using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class ParticleCircle : MonoBehaviour
{
    public float startDelay         = 0.0f;
    public float startLifetime      = 5.0f;
    public float startSpeed         = 5.0f;
    public float startSize          = 1.0f;
    public int   maxParticles       = 1000;

    public Color startColor         = Color.white;
    public float gravityModifier    = 0.0f;    

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
    {}
    public Sphere sphere;
    
    [System.Serializable]
    public struct Collision
    {
        public MeshFilter[] planes; // Unity cannot serialize "Plane"
    }

    public Collision collision;
    
    static private int MAX_COLLISION_PLANES = 4;
    
    private void allocateParticles(int size)
    { 
        Vector3[] vertices = new Vector3[4*size];
        int    [] tri      = new int    [6*size];
        Vector2[] uv       = new Vector2[4*size];
        Vector2[] id       = new Vector2[4*size];

        Vector3 emitter_pos = gameObject.transform.position;

        for (int i = 0; i < size; i++)
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
        
        mesh.vertices  = vertices;
        mesh.triangles = tri;
        mesh.uv        = uv;
        mesh.uv2       = id;
        
        //@TODO Calc bounds -> particle render out clipping space.
        //mesh.bounds = new Bounds(emitter_pos, new Vector3(100, 100, 100));
    }
    
    void Awake()
    {
        Renderer renderer = GetComponent<Renderer>();
        renderer.sharedMaterial.shader = Shader.Find("Unlit/ParticleCircle");

        int max_p = (int)Mathf.Ceil(startLifetime*emission.rateOverTime);
        if (max_p > maxParticles){
            max_p = maxParticles;
        }
        allocateParticles(max_p);
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
        if (renderer.sharedMaterial.GetVector("_StartColor") != (Vector4)startColor){
            renderer.sharedMaterial.SetVector("_StartColor", startColor);
        }
        if (renderer.sharedMaterial.GetFloat("_GravityModifier") != gravityModifier){
            renderer.sharedMaterial.SetFloat("_GravityModifier", gravityModifier);
        }
        
        for (int i = 0; i < MAX_COLLISION_PLANES; i++)
        {
            Vector4 plane_center4 = new Vector4(0.0f, 0.0f, 0.0f, 1.0f);
            Vector4 plane_normal4 = new Vector4(0.0f, 0.0f, 0.0f, 1.0f);
            
            if (collision.planes.Length > i && collision.planes[i] != null){
                Vector3 plane_center = collision.planes[i].transform.position;
                Vector3 plane_up = collision.planes[i].transform.up;
            
                plane_center4 = new Vector4(plane_center.x, plane_center.y, plane_center.z, 1.0f);
                plane_normal4 = new Vector4(plane_up.x, plane_up.y, plane_up.z, 1.0f);

                // Fix Unity normal precision
                if (plane_normal4.x < 0.000001f && plane_normal4.x > -0.000001f) plane_normal4.x = 0;
                if (plane_normal4.y < 0.000001f && plane_normal4.y > -0.000001f) plane_normal4.y = 0;
                if (plane_normal4.z < 0.000001f && plane_normal4.z > -0.000001f) plane_normal4.z = 0;
            }
            
            if (renderer.sharedMaterial.GetVector("_CollisionPlaneCenter"+i) != plane_center4){
                renderer.sharedMaterial.SetVector("_CollisionPlaneCenter"+i, plane_center4);
            }
            if (renderer.sharedMaterial.GetVector("_CollisionPlaneNormal"+i) != plane_normal4){
                renderer.sharedMaterial.SetVector("_CollisionPlaneNormal"+i, plane_normal4);
            }
        }

        int max_p = (int)Mathf.Ceil(startLifetime*emission.rateOverTime);
        if (max_p > maxParticles){
            max_p = maxParticles;
        }

        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (max_p != (mesh.vertexCount*4)){
            allocateParticles(max_p);
        }
#endif
        //@TODO: KILL EMITTER
    }
    
    void OnValidate()
    {
        EditorApplication.update = TriggerUpdate;

        if (collision.planes != null && collision.planes.Length > MAX_COLLISION_PLANES) {
            Debug.LogWarning("Up to " + MAX_COLLISION_PLANES + " collision planes!");
            System.Array.Resize(ref collision.planes, MAX_COLLISION_PLANES);
        }
    }
}