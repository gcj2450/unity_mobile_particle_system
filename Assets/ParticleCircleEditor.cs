using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ParticleCircle))]
[CanEditMultipleObjects]
public class ParticleCircleEditor : Editor
{
	SerializedProperty startLifetime;
	SerializedProperty startDelay;
	SerializedProperty startSize;
	SerializedProperty startSpeed;
	SerializedProperty maxParticles;

	SerializedProperty startColor;
	SerializedProperty emission;

	SerializedProperty shape;
	SerializedProperty cone;
	SerializedProperty sphere;
	
	void OnEnable()
	{
		startLifetime = serializedObject.FindProperty("startLifetime");
		startDelay 	  = serializedObject.FindProperty("startDelay");
		startSize 	  = serializedObject.FindProperty("startSize");
		startSpeed 	  = serializedObject.FindProperty("startSpeed");
		maxParticles  = serializedObject.FindProperty("maxParticles");

		startColor = serializedObject.FindProperty("startColor");
		
		emission = serializedObject.FindProperty("emission");
		
		shape  = serializedObject.FindProperty("shape");
		cone   = serializedObject.FindProperty("cone");
		sphere = serializedObject.FindProperty("sphere");
	}
	
	public override void OnInspectorGUI()
	{
		ParticleCircle pc = (ParticleCircle)target;
		
		serializedObject.Update();
		EditorGUILayout.PropertyField(startDelay);
		EditorGUILayout.PropertyField(startLifetime);
		EditorGUILayout.PropertyField(startSpeed);
		EditorGUILayout.PropertyField(startSize);
		EditorGUILayout.PropertyField(maxParticles);

		EditorGUILayout.PropertyField(startColor);
	
		EditorGUILayout.PropertyField(emission, true);

		EditorGUILayout.PropertyField(shape);
		if (pc != null){
			if (pc.shape == ParticleCircle.ShapeType.Cone) {
				EditorGUILayout.PropertyField(cone, true);
			} else {
				EditorGUILayout.PropertyField(sphere, true);
			}	
		}
		
		serializedObject.ApplyModifiedProperties();
	}
	
}