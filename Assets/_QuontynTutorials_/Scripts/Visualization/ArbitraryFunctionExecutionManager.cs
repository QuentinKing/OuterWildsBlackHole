using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

namespace ArbitraryFunctionManager
{
    // Have a list of animatable functions that you can execute one at a time from some input. 
    // For doing visualizations while recording

    // An arbitrary function can be overridden and do whatever it wants.
    // This class will call them in order and start timers that update their OnStep function.
    public abstract class ArbitraryFunction
    {
        public bool isOneShot;

        public float duration;
        public float priority;
        public Tweens.Type tweenType;

        public abstract void OnStart();
        public abstract void OnStep(float t);
        public abstract void OnEnd();
    }

    public class ArbitraryFunctionExecutionManager : MonoBehaviour
    {

        // Singleton
        private static ArbitraryFunctionExecutionManager _instance;
        public static ArbitraryFunctionExecutionManager Get()
        {
            if (_instance == null)
            {
                _instance = new GameObject("ArbitraryFunctionManager").AddComponent<ArbitraryFunctionExecutionManager>();
                return _instance;
            }
            else
            {
                return _instance;
            }
        }

        public void Start()
        {
            if (_instance == null)
                _instance = this;
        }


        // Buffer
        public List<ArbitraryFunction> instructionBuffer = new List<ArbitraryFunction>();

        private IEnumerator DoInstruction(ArbitraryFunction instruction)
        {
            float normalizedTime = 0;
            while (normalizedTime <= 1f)
            {
                normalizedTime += Time.deltaTime / instruction.duration;
                float easedT = Tweens.EvaluateTweenFromType(instruction.tweenType, normalizedTime);
                instruction.OnStep(easedT);
                yield return null;
            }

            instruction.OnEnd();
        }

        public void EnqueueInstruction(ArbitraryFunction data)
        {
            instructionBuffer.Add(data);
        }

        public void Update()
        {
            if (Input.GetKeyDown(KeyCode.Space))
            {
                // Execute all instructions with the lowest priority
                float minPriority = float.MaxValue;
                foreach (ArbitraryFunction instruction in instructionBuffer)
                {
                    minPriority = Mathf.Min(instruction.priority, minPriority);
                }

                for (int i = instructionBuffer.Count-1; i >= 0; i--)
                {
                    ArbitraryFunction instruction = instructionBuffer[i];
                    if (instruction.priority == minPriority)
                    {
                        if (instruction.isOneShot)
                        {
                            instruction.OnStep(0.0f);
                        }
                        else
                        {
                            instruction.OnStart();
                            IEnumerator coroutine = DoInstruction(instruction);
                            StartCoroutine(coroutine);
                        }

                        instructionBuffer.RemoveAt(i);
                    }
                }
            }
        }
    }
}