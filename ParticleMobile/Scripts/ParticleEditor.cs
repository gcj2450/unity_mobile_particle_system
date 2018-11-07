using UnityEditor;

[CustomEditor(typeof(ParticleBillboard))]
[CanEditMultipleObjects]
public class ParticleCircleEditor : Editor
{
	SerializedProperty startLifetime;
	SerializedProperty startDelay;
	SerializedProperty startSize;
	SerializedProperty startSpeed;
	SerializedProperty maxParticles;

	SerializedProperty startColor;
	SerializedProperty gravityModifier;
	SerializedProperty emission;

	SerializedProperty shape;
	SerializedProperty cone;
	SerializedProperty sphere;
	SerializedProperty collision;
	
	void OnEnable()
	{
		startLifetime = serializedObject.FindProperty("startLifetime");
		startDelay 	  = serializedObject.FindProperty("startDelay");
		startSize 	  = serializedObject.FindProperty("startSize");
		startSpeed 	  = serializedObject.FindProperty("startSpeed");
		maxParticles  = serializedObject.FindProperty("maxParticles");

		startColor 		= serializedObject.FindProperty("startColor");
		gravityModifier = serializedObject.FindProperty("gravityModifier");
		emission 		= serializedObject.FindProperty("emission");
		
		shape  	  = serializedObject.FindProperty("shape");
		cone   	  = serializedObject.FindProperty("cone");
		sphere 	  = serializedObject.FindProperty("sphere");
		collision = serializedObject.FindProperty("collision");
	}
	
	public override void OnInspectorGUI()
	{
		ParticleBillboard pc = (ParticleBillboard)target;
		
		serializedObject.Update();
		EditorGUILayout.PropertyField(startDelay);
		EditorGUILayout.PropertyField(startLifetime);
		EditorGUILayout.PropertyField(startSpeed);
		EditorGUILayout.PropertyField(startSize);
		EditorGUILayout.PropertyField(maxParticles);

		EditorGUILayout.PropertyField(startColor);
		EditorGUILayout.PropertyField(gravityModifier);
	
		EditorGUILayout.PropertyField(emission, true);

		EditorGUILayout.PropertyField(shape);
		if (pc != null){
			if (pc.shape == ParticleBillboard.ShapeType.Sphere) {
				EditorGUILayout.PropertyField(sphere, true);
			} else {
				// Default Shape Cone
				EditorGUILayout.PropertyField(cone, true);
			}	
		}

		EditorGUILayout.PropertyField(collision, true);

		serializedObject.ApplyModifiedProperties();
	}
	
}