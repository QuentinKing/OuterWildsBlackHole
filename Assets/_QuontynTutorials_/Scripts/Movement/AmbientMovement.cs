using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AmbientMovement : MonoBehaviour
{
    private Vector3 m_originalPosition = Vector3.zero;

    public bool DoTranslation = true;
    public Vector3 MovementVector = Vector3.up;
    public float MovementDistance = 1.0f;
    public float MovementFrequency = 1.0f;
    public float MovementOffset = 0.0f;

    public bool DoRotation = true;

    public void Start()
    {
        m_originalPosition = this.transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        if (DoTranslation)
        {
            transform.position = m_originalPosition + MovementVector * MovementDistance * Mathf.Sin(MovementOffset + Time.time * MovementFrequency);
        }

        if (DoRotation)
        {
            transform.RotateAround(transform.position, transform.up, Mathf.Sin(Time.deltaTime));
        }
    }
}
