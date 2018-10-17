using UnityEngine;
using UnityEditor;
using System;
     
[CustomEditor(typeof(ParticleCircle))]
[CanEditMultipleObjects]
public class ParticleCircleEditor : Editor
{
	SerializedProperty particleSize;

	void OnEnable()
	{
		particleSize = serializedObject.FindProperty("particleSize");
	}
	
	public override void OnInspectorGUI()
	{
		serializedObject.Update();
		EditorGUILayout.PropertyField(particleSize);
		serializedObject.ApplyModifiedProperties();
	}
	
}