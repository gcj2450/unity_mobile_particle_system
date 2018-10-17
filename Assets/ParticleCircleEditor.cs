using UnityEngine;
using UnityEditor;
using System;
     
[CustomEditor(typeof(ParticleCircle))]
[CanEditMultipleObjects]
public class ParticleCircleEditor : Editor
{
	SerializedProperty particleSize;
	SerializedProperty shape;
	SerializedProperty cone;
	SerializedProperty sphere;

	void OnEnable()
	{
		particleSize = serializedObject.FindProperty("particleSize");
		shape 		 = serializedObject.FindProperty("shape");
		cone 		 = serializedObject.FindProperty("cone");
		sphere 		 = serializedObject.FindProperty("sphere");
	}
	
	public override void OnInspectorGUI()
	{
		ParticleCircle pc = (ParticleCircle)target;
		
		serializedObject.Update();
		EditorGUILayout.PropertyField(particleSize);
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