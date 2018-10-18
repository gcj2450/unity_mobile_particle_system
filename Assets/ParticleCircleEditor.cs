using UnityEngine;
using UnityEditor;
using System;
     
[CustomEditor(typeof(ParticleCircle))]
[CanEditMultipleObjects]
public class ParticleCircleEditor : Editor
{
	SerializedProperty startLifetime;
	SerializedProperty particleSize;
	SerializedProperty particleSpeedScale;
	SerializedProperty maxParticles;

	SerializedProperty emission;

	SerializedProperty shape;
	SerializedProperty cone;
	SerializedProperty sphere;
	
	void OnEnable()
	{
		startLifetime 		= serializedObject.FindProperty("startLifetime");
		particleSize 		= serializedObject.FindProperty("particleSize");
		particleSpeedScale 	= serializedObject.FindProperty("particleSpeedScale");
		maxParticles 		= serializedObject.FindProperty("maxParticles");
		
		emission = serializedObject.FindProperty("emission");
		
		shape 	= serializedObject.FindProperty("shape");
		cone 	= serializedObject.FindProperty("cone");
		sphere 	= serializedObject.FindProperty("sphere");
	}
	
	public override void OnInspectorGUI()
	{
		ParticleCircle pc = (ParticleCircle)target;
		
		serializedObject.Update();
		EditorGUILayout.PropertyField(startLifetime);
		EditorGUILayout.PropertyField(particleSize);
		EditorGUILayout.PropertyField(particleSpeedScale);
		EditorGUILayout.PropertyField(maxParticles);

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