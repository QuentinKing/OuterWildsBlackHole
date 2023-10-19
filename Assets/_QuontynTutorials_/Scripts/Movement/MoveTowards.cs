using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveTowards : MonoBehaviour
{
    public Vector3 target;
    public float speed;
    public bool onStart = false;

    private bool shouldMove = false;

    private void Start()
    {
        shouldMove = onStart;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            shouldMove = true;
        }

        if (shouldMove)
        {
            this.transform.position = Vector3.Lerp(this.transform.position, target, speed * Time.deltaTime);
        }
    }
}
