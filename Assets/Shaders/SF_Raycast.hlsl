#ifndef RAYCAST_INCLUDE
#define RAYCAST_INCLUDE


void Raycast_float(float3 RayOrigin, float3 RayDirection, float3 SphereOrigin, float SphereSize, 
                    out float Hit, out float3 HitPosition, out float3 HitNormal)
{
    HitPosition = float3(0.0, 0.0, 0.0);
    HitNormal = float3(0.0, 0.0, 0.0);

    float t = 0.0f;
    float3 L = SphereOrigin - RayOrigin;
    float tca = dot(L, -RayDirection);

    if (tca < 0)
    {
        Hit = 0.0f;
        return;
    }

    float d2 = dot(L, L) - tca * tca;
    float radius2 = SphereSize * SphereSize;

    if (d2 > radius2)
    {
        Hit = 0.0f;
        return;
    }

    float thc = sqrt(radius2 - d2);
    t = tca - thc; 
    
    Hit = 1.0f;
    HitPosition = RayOrigin - RayDirection * t;
    HitNormal = normalize(HitPosition - SphereOrigin);
}


    void GetScreenPosition_float(float3 Position, out float2 ScreenPosition, out float2 ScreenPositionAspectRatio)
    {
        float4 screen = ComputeScreenPos(TransformWorldToHClip(Position), _ProjectionParams.x);
        ScreenPosition = screen.xy / abs(screen.w);

        float aspectRatio = _ScreenParams.y / _ScreenParams.x;
        ScreenPositionAspectRatio = float2(ScreenPosition.x, ScreenPosition.y * aspectRatio);
    }

void GetCameraRightWS_float(out float3 CameraRightWS)
{
    CameraRightWS = mul((float3x3)unity_CameraToWorld, float3(1, 0, 0));
}

void MirrorUVCoordinates_float(float2 UVs, out float2 NewUVs)
{
    // Mirror U coordinate
    if (UVs.x < 0.0 || UVs.x > 1.0)
        NewUVs.x = 1.0 - abs((UVs.x - 2.0 * floor(UVs.x / 2.0)) - 1.0);
    else
        NewUVs.x = UVs.x;

    // Mirror V coordinate
    if (UVs.y < 0.0 || UVs.y > 1.0)
        NewUVs.y = 1.0 - abs((UVs.y - 2.0 * floor(UVs.y / 2.0)) - 1.0);
    else
        NewUVs.y = UVs.y;

}


#endif