using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RevolveAround : MonoBehaviour
{
    public Vector3 axis = Vector3.up;
    public float speed = 10.0f;

    private void Update()
    {
        transform.RotateAround(Vector3.zero, axis, speed * Time.deltaTime);
    }
}
