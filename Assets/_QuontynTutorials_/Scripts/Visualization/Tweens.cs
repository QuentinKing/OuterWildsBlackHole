using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// https://easings.net/
public class Tweens
{
    public enum Type
    { 
        LINEAR,
        IN_SINE,
        OUT_SINE,
        IN_OUT_SINE,
        IN_QUAD,
        OUT_QUAD,
        IN_OUT_QUAD
    }

    public static float EvaluateTweenFromType(Tweens.Type tweenType, float t)
    {
        switch (tweenType)
        {
            default:
            case Tweens.Type.LINEAR:
                return Linear(t);
            case Tweens.Type.OUT_SINE:
                return OutSine(t);
            case Tweens.Type.IN_SINE:
                return InSine(t);
            case Tweens.Type.IN_OUT_SINE:
                return InOutSine(t);
            case Tweens.Type.IN_QUAD:
                return InQuadratic(t);
            case Tweens.Type.OUT_QUAD:
                return OutQuadratic(t);
            case Tweens.Type.IN_OUT_QUAD:
                return InOutQuadratic(t);
        }
    }

    public static float Linear(float t)
    {
        return t;
    }

    public static float InSine(float t)
    {
        return 1.0f - Mathf.Cos((t * Mathf.PI) / 2.0f);
    }

    public static float OutSine(float t)
    {
        return Mathf.Sin((t * Mathf.PI) / 2.0f);
    }

    public static float InOutSine(float t)
    {
        return -(Mathf.Cos(Mathf.PI * t) - 1.0f) / 2.0f;
    }

    public static float InQuadratic(float t)
    {
        return t * t;
    }

    public static float OutQuadratic(float t)
    {
        return 1.0f - (1.0f - t) * (1.0f - t);
    }

    public static float InOutQuadratic(float t)
    {
        return t < 0.5f ? 2.0f * t * t : 1.0f - Mathf.Pow(-2.0f * t + 2.0f, 2.0f) / 2.0f;
    }


}
