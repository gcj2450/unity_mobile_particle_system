using System.Linq;
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
    public struct Emission{
        public float rateOverTime;
    }
    public Emission emission;
    
    public enum ShapeType{ Cone, Sphere }
    public ShapeType shape;

    [System.Serializable]
    public struct Cone{
        public float angle;
    }
    public Cone cone;
    
    [System.Serializable]
    public struct Sphere{}
    public Sphere sphere;
    
    [System.Serializable]
    public struct Collision{
        public MeshFilter[] planes; // Unity cannot serialize "Plane"
    }
    public Collision collision;

    private Mesh mesh;
    private static int MAX_COLLISION_PLANES = 4;
    
    void Awake()
    {
        GetComponent<Renderer>().material = new Material(Shader.Find("Unlit/ParticleCircle"));
        
#if UNITY_EDITOR
        MeshFilter mf = GetComponent<MeshFilter>();
        Mesh meshCopy = Mesh.Instantiate(mf.sharedMesh) as Mesh;
        mesh = mf.mesh = meshCopy;
        mesh.name = "Particle Quad (Editor)";
#else
        mesh = GetComponent<MeshFilter>().mesh;
#endif
        OnValidate();
    }

    public void TriggerUpdate()
    {
        EditorUtility.SetDirty(this);
    }
    
    void OnValidate()
    {
        EditorApplication.update = TriggerUpdate;

        if (collision.planes != null && collision.planes.Length > MAX_COLLISION_PLANES) {
            Debug.LogWarning("Up to " + MAX_COLLISION_PLANES + " collision planes!");
            System.Array.Resize(ref collision.planes, MAX_COLLISION_PLANES);
        }

        Renderer renderer = GetComponent<Renderer>();
        if (renderer.sharedMaterial == null){
            return;
        }
        Material tempMat = new Material(renderer.sharedMaterial);

        tempMat.SetFloat("_StartSize", startSize);
        tempMat.SetFloat("_RateOverTime", emission.rateOverTime);
        tempMat.SetFloat("_StartSpeed", startSpeed);
        tempMat.SetFloat("_StartLifeTime", startLifetime);
        tempMat.SetFloat("_StartDelay", startDelay);
        tempMat.SetInt("_Shape", (int)shape);
        tempMat.SetFloat("_ConeAngle", cone.angle);
        tempMat.SetVector("_StartColor", startColor);
        tempMat.SetFloat("_GravityModifier", gravityModifier);

        for (int i = 0; i < MAX_COLLISION_PLANES; i++){
            Vector4 plane_center4 = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);
            Vector4 plane_normal4 = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);

            if (collision.planes.Length > i && collision.planes[i] != null) {
                Vector3 plane_center = collision.planes[i].transform.position;
                Vector3 plane_up = collision.planes[i].transform.up;

                plane_center4 = new Vector4(plane_center.x, plane_center.y, plane_center.z, 1.0f);
                plane_normal4 = new Vector4(plane_up.x, plane_up.y, plane_up.z, 1.0f);

                // Fix Unity normal precision
                if (plane_normal4.x < 0.000001f && plane_normal4.x > -0.000001f) plane_normal4.x = 0;
                if (plane_normal4.y < 0.000001f && plane_normal4.y > -0.000001f) plane_normal4.y = 0;
                if (plane_normal4.z < 0.000001f && plane_normal4.z > -0.000001f) plane_normal4.z = 0;
            }

            Vector3 normal = Vector3.Normalize(plane_normal4);
            float plane_d = -1 * Vector3.Dot(normal, plane_center4);
            Vector4 plane_eq = new Vector4(normal.x, normal.y, normal.z, plane_d);

            if (tempMat.GetVector("_CollisionPlaneEquation" + i) != plane_eq)
                tempMat.SetVector("_CollisionPlaneEquation" + i, plane_eq);
        }

        renderer.material = tempMat;

        setMesh();
    }

    private void setMesh()
    {
        // Min number particles needed:
        // If particles lives 5s and we spawn 2 per sec that means 10 particles at same time being rendered.
        // When a particle "die" it's reused by the shader.
        int size = (int) Mathf.Ceil(startLifetime * emission.rateOverTime);
        // Check/Adjust size.
        if (size > maxParticles) size = maxParticles;
        if (size > ParticleMeshPool.MAX_PARTICLES) size = ParticleMeshPool.MAX_PARTICLES;
        if (mesh == null || size == (mesh.vertexCount / 4))
            return;
        
        // Retrieve particles from pool.
        var pool = ParticleMeshPool.GetParticleMeshes();

        mesh.Clear();
        mesh.vertices  = pool.pos.Take(size * 4).ToArray();
        mesh.uv        = pool.uv .Take(size * 4).ToArray();
        mesh.triangles = pool.tri.Take(size * 6).ToArray();
        mesh.uv2       = pool.id .Take(size * 4).ToArray();

        Debug.Log(mesh.vertexCount.ToString());

        float bound_len = startLifetime * startSpeed;
        mesh.bounds = new Bounds(new Vector3(0, 0, 0), new Vector3(bound_len, bound_len, bound_len));
    }
}