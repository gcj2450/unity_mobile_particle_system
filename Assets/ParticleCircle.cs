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

    private Mesh mesh;
    
    static private int MAX_COLLISION_PLANES = 4;
    
    private void allocateParticles(int size)
    { 
        Vector3[] vertices = new Vector3[4*size];
        int    [] tri      = new int    [6*size];
        Vector2[] uv       = new Vector2[4*size];
        Vector2[] id       = new Vector2[4*size];

        Vector3 emitter_pos = new Vector3(0,0,0);

        Debug.Log(emitter_pos.ToString());
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
            Vector2 id_val = new Vector2(i + 1, 0);
            id[idx4 + 0] = id_val;
            id[idx4 + 1] = id_val;
            id[idx4 + 2] = id_val;
            id[idx4 + 3] = id_val;
        }

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
        renderer.material = new Material(Shader.Find("Unlit/ParticleCircle"));

#if UNITY_EDITOR
        MeshFilter mf = GetComponent<MeshFilter>();
        Mesh meshCopy = Mesh.Instantiate(mf.sharedMesh) as Mesh;
        mesh = mf.mesh = meshCopy;
#else
        mesh = GetComponent<MeshFilter>().mesh;
#endif

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
        var tempMaterial = new Material(Shader.Find("Unlit/ParticleCircle"));
        
        if (tempMaterial.GetFloat("_StartSize") != startSize){
            tempMaterial.SetFloat("_StartSize", startSize);
        }
        if (tempMaterial.GetFloat("_RateOverTime") != emission.rateOverTime){
            tempMaterial.SetFloat("_RateOverTime", emission.rateOverTime);
        }
        if (tempMaterial.GetFloat("_StartSpeed") != startSpeed){
            tempMaterial.SetFloat("_StartSpeed", startSpeed);
        }
        if (tempMaterial.GetFloat("_StartLifeTime") != startLifetime){
            tempMaterial.SetFloat("_StartLifeTime", startLifetime);
        }
        if (tempMaterial.GetFloat("_StartDelay") != startDelay){
            tempMaterial.SetFloat("_StartDelay", startDelay);
        }
        if (tempMaterial.GetInt("_Shape") != (int)shape){
            tempMaterial.SetInt("_Shape", (int)shape);
        }
        if (tempMaterial.GetFloat("_ConeAngle") != cone.angle){
            tempMaterial.SetFloat("_ConeAngle", cone.angle);
        }
        if (tempMaterial.GetVector("_StartColor") != (Vector4)startColor){
            tempMaterial.SetVector("_StartColor", startColor);
        }
        if (tempMaterial.GetFloat("_GravityModifier") != gravityModifier){
            tempMaterial.SetFloat("_GravityModifier", gravityModifier);
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
            
            if (tempMaterial.GetVector("_CollisionPlaneCenter"+i) != plane_center4){
                tempMaterial.SetVector("_CollisionPlaneCenter"+i, plane_center4);
            }
            if (tempMaterial.GetVector("_CollisionPlaneNormal"+i) != plane_normal4){
                tempMaterial.SetVector("_CollisionPlaneNormal"+i, plane_normal4);
            }
        }

        renderer.sharedMaterial = tempMaterial;

        int max_p = (int)Mathf.Ceil(startLifetime*emission.rateOverTime);
        if (max_p > maxParticles){
            max_p = maxParticles;
        }

        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (max_p != (mesh.vertexCount/4)){
            allocateParticles(max_p);
        }
#endif
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