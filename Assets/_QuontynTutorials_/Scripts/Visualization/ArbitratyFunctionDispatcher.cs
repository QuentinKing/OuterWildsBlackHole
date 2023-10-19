using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ArbitraryFunctionManager;
using System.Linq;
using UnityEditor.Rendering.Universal;

public class ArbitratyFunctionDispatcher : MonoBehaviour
{

    // TRANSLATION OFFSET
    [System.Serializable]
    public class MovementOffsetAnimaionFunction : ArbitraryFunction
    {
        public GameObject obj;
        public Vector3 offset;

        private Vector3 distanceAdded;

        public override void OnStart()
        { 
            distanceAdded = Vector3.zero;
        }

        public override void OnStep(float t)
        {
            Vector3 total = offset * t;
            Vector3 toAdd = total - distanceAdded;

            obj.transform.position += toAdd;

            distanceAdded += toAdd;
        }

        public override void OnEnd()
        {
        }
    }
    public List<MovementOffsetAnimaionFunction> TranslationOffsetCommands;

    // ROTATION OFFSET
    [System.Serializable]
    public class RotationOffsetAntimaionFunction : ArbitraryFunction
    {
        public GameObject obj;

        public Vector3 rotationOffset;
        private Vector3 rotationAdded;

        public override void OnStart()
        {
            rotationAdded = Vector3.zero;
        }

        public override void OnStep(float t)
        {
            Vector3 total = rotationOffset * t;
            Vector3 toAdd = total - rotationAdded;

            obj.transform.Rotate(toAdd);

            rotationAdded += toAdd;
        }

        public override void OnEnd()
        {
        }
    }
    public List<RotationOffsetAntimaionFunction> RotationOffsetCommands;



    // TRANSFORM LERPS
    [System.Serializable]
    public class TransformLerps : ArbitraryFunction
    {
        public GameObject obj;

        [System.Serializable]
        public class TransformData
        {
            public Vector3 position = Vector3.zero;
            public Vector3 rotation = Vector3.zero;
            public Vector3 scale = Vector3.one;
        }

        public TransformData start;
        public TransformData end;

        public override void OnStart()
        {

        }

        public override void OnStep(float t)
        {
            obj.transform.position = Vector3.Lerp(start.position, end.position, t);
            obj.transform.rotation = Quaternion.Slerp(Quaternion.Euler(start.rotation), Quaternion.Euler(end.rotation), t);
            obj.transform.localScale = Vector3.Lerp(start.scale, end.scale, t);
        }

        public override void OnEnd()
        {
        }
    }
    public List<TransformLerps> TransformLerpCommands;


    // MATERIAL PARAM LERPS
    [System.Serializable]
    public class SetMaterialFloatParameter : ArbitraryFunction
    {
        public GameObject obj;
        public bool invertLerp;
        public string materialParameterName;

        public override void OnStart()
        {

        }

        public override void OnStep(float t)
        {
            Renderer[] renderers = obj.GetComponents<Renderer>();

            foreach (var renderer in renderers)
            {
                Material[] mats = renderer.materials;
                foreach (var mat in mats)
                {
                    if (invertLerp)
                    {
                        mat.SetFloat(materialParameterName, 1.0f-t);
                    }
                    else 
                    {
                        mat.SetFloat(materialParameterName, t);
                    }
                }
            }
        }

        public override void OnEnd()
        {
        }
    }
    public List<SetMaterialFloatParameter> MaterialFloatCommands;


    // TODO:
    // - Need a way to modify a bunch of objects at once

    public void Start()
    {
        // Queue Animation Tasks
        foreach (var offsetAnim in TranslationOffsetCommands)
        {
            ArbitraryFunctionExecutionManager.Get().EnqueueInstruction(offsetAnim);
        }
        foreach (var rotationAnim in RotationOffsetCommands)
        {
            ArbitraryFunctionExecutionManager.Get().EnqueueInstruction(rotationAnim);
        }
        foreach (var transformLerp in TransformLerpCommands)
        {
            ArbitraryFunctionExecutionManager.Get().EnqueueInstruction(transformLerp);
        }
        foreach (var materialFloatParam in MaterialFloatCommands)
        {
            ArbitraryFunctionExecutionManager.Get().EnqueueInstruction(materialFloatParam);
        }
    }
}
