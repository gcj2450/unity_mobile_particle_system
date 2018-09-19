using UnityEngine;
  
  
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class PointCloud : MonoBehaviour {
  
	private Mesh mesh;
	int numPoints = 2;
  
	void Start () 
	{
		mesh = new Mesh();
  
		GetComponent<MeshFilter>().mesh = mesh;
		CreateMesh();
	}
  
	void CreateMesh() 
	{
		Vector3[] points 	= new Vector3[numPoints];
		int[] indices 		= new int[numPoints];
		
		points[0]  = new Vector3(0,0,0);
		indices[0] = 0;
  
		points[1]  = new Vector3(0,0,0);
		indices[1] = 1;
		
		mesh.vertices = points;
		mesh.SetIndices(indices, MeshTopology.Points, 0);
	}
}