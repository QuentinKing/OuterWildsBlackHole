using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

// Learning custom editor scripts
[CustomEditor(typeof(Transform))]
[CanEditMultipleObjects]
public class CustomTransformComponent : Editor
{
    private const float kResetButtonWidth = 20.0f;

    SerializedProperty m_LocalPosition;
    SerializedProperty m_LocalRotation;
    SerializedProperty m_LocalScale;
    object m_TransformRotationGUILocal;

    [MenuItem("CONTEXT/Transform/Reset All")]
    private static void RandomRotation(MenuCommand command)
    {
        var transform = command.context as Transform;

        Undo.RecordObject(transform, "Set Random Rotation");
        transform.localPosition = Vector3.zero;
        transform.rotation = Quaternion.identity;
        transform.localScale = Vector3.one;
    }

    public void OnEnable()
    {
        /*
        SerializedProperty property = serializedObject.GetIterator();
        while (property.Next(true))
        {
            Debug.Log("Property name: " + property.name);
        }
        */

        m_LocalPosition = serializedObject.FindProperty("m_LocalPosition");
        m_LocalRotation = serializedObject.FindProperty("m_LocalRotation");
        m_LocalScale = serializedObject.FindProperty("m_LocalScale");

        // Gotta hijack the rotation GUI from unity
        if (m_TransformRotationGUILocal == null)
            m_TransformRotationGUILocal = System.Activator.CreateInstance(typeof(SerializedProperty).Assembly.GetType("UnityEditor.TransformRotationGUI", false, false));
        m_TransformRotationGUILocal.GetType().GetMethod("OnEnable").Invoke(m_TransformRotationGUILocal, new object[] { m_LocalRotation, new GUIContent("Rotation") });
    }
    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        Transform t = (Transform)target;

        // Position
        using (new EditorGUILayout.HorizontalScope())
        {
            EditorGUILayout.PropertyField(m_LocalPosition, new GUIContent("Position"));

            if (GUILayout.Button(new GUIContent("R", "Reset Position"), GUILayout.Width(kResetButtonWidth)))
                m_LocalPosition.vector3Value = Vector3.zero;
        }

        // Rotation
        using (new EditorGUILayout.HorizontalScope())
        {
            m_TransformRotationGUILocal.GetType().GetMethod("RotationField", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic, null, new[] { typeof(bool) }, null).Invoke(m_TransformRotationGUILocal, new object[] { false });

            if (GUILayout.Button(new GUIContent("R", "Reset Rotation"), GUILayout.Width(kResetButtonWidth)))
                m_LocalRotation.quaternionValue = Quaternion.identity;
        }

        // Scale
        using (new EditorGUILayout.HorizontalScope())
        {
            EditorGUILayout.PropertyField(m_LocalScale, new GUIContent("Scale"));

            if (GUILayout.Button(new GUIContent("R", "Reset Scale"), GUILayout.Width(kResetButtonWidth)))
                m_LocalScale.vector3Value = Vector3.one;
        }

        serializedObject.ApplyModifiedProperties();
    }
}