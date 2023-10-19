/*
    Get a random value from uv position
*/
float CustomRandom(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
}

/*
    Pan a rounded trail across a UV.

    Cycle time is how long the trail animates through the uv, delay is the time in between cycles

    The aa parameter determines the smoothing of the trail edges
*/
float EvaluateTrail(float2 uv, float cycleTime, float delay, float offset, float width, float thickness, float aa)
{
    float totalCycleTime = delay + cycleTime;
    float curTime = (_Time.y + offset) % totalCycleTime;

    /* Goes from 0 -> 1 after the delay */
    float t = max(curTime - delay, 0.0) / cycleTime;

    /* Right part of the trail needs to start at 0, and the left part of the trail needs to end at 1 */
    float trailUv = lerp(t - width, 1.0 + width, t); // Probably a way to simplify this!
    float2 trailPosition = float2(trailUv, 0.5);

    /* SDF of a circle, smoothsteped in order to do anti aliasing */
    uv.y = (uv.y - 0.5) * (1.0 / thickness) + 0.5;
    float trailSample = abs(min(length(uv - trailPosition) - width, 0.0));
    trailSample = smoothstep(0.0, aa, trailSample);

    return trailSample;
}


/* HSV <-> RGB Conversions */
// Code from https://gist.github.com/sugi-cho/6a01cae436acddd72bdf
float3 RGB2HSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
float3 HSV2RGB(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


/*
    Triplanar projections
*/
float4 TriPlanarMap(sampler2D map, float3 pos, float3 n)
{
    float3 weights = abs(n);
    float4 x = tex2D(map, pos.zy);
    float4 y = tex2D(map, pos.xz);
    float4 z = tex2D(map, pos.xy);
    weights = weights / (weights.x + weights.y + weights.z);
    return (x * weights.x + y * weights.y + z * weights.z);
}
float4 TriPlanarMapVertex(sampler2D map, float3 pos, float3 n)
{
    float3 weights = abs(n);
    float4 x = tex2Dlod(map, float4(pos.zy, 0, 0));
    float4 y = tex2Dlod(map, float4(pos.xz, 0, 0));
    float4 z = tex2Dlod(map, float4(pos.xy, 0, 0));
    weights = weights / (weights.x + weights.y + weights.z);
    return (x * weights.x + y * weights.y + z * weights.z);
}


/*
    Wind Offset
*/
float3 WindOffsetVertex(float3 ogPosition, float normalOS, float3 windDirection, sampler2D noiseMap, float2 windSpeeds, float2 windIntensities)
{
    /* For development mostly, so I don't have to worry about object scale, should optimize out in any real project */
    float3 ObjectScale =
        float3(
            length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
            length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
            length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
            );
    float3 ObjectPosition = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

    /* Vertex wind animation */
    float4 WindDirection = normalize(mul(GetWorldToObjectMatrix(), windDirection));

    float windAmplitudeMain = TriPlanarMapVertex(noiseMap, (ogPosition + ObjectPosition + (_Time * windSpeeds.x)) * 0.8, normalOS).r;
    float3 windOffsetMain = WindDirection * windAmplitudeMain * (1.0 / ObjectScale) * windIntensities.x;

    float windAmplitudeSecondary = TriPlanarMapVertex(noiseMap, (ogPosition + ObjectPosition + (_Time * windSpeeds.y)) * 1.5, normalOS).r;
    float3 windOffsetSecondary = WindDirection * windAmplitudeSecondary * (1.0 / ObjectScale) * windIntensities.y;

    float3 newInputPosition = ogPosition + windOffsetMain + windOffsetSecondary;

    return newInputPosition;
}


/* Transmission Lighting */
float3 TransmissionLighting(InputData inputData, float3 albedo, float shadowValue, float transmissionValue)
{
    float3 transmissionColor = float3(0.0, 0.0, 0.0);

    Light mainLight = GetMainLight(inputData.shadowCoord);
    float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
    mainAtten = lerp(mainAtten, mainAtten * mainLight.shadowAttenuation, shadowValue);
    half3 mainTransmission = max(0, -dot(inputData.normalWS, mainLight.direction)) * mainAtten * transmissionValue;
    transmissionColor.rgb += albedo * mainTransmission;

    int transPixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < transPixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, inputData.positionWS);
        float3 atten = light.color * light.distanceAttenuation;
        atten = lerp(atten, atten * light.shadowAttenuation, shadowValue);

        half3 transmission = max(0, -dot(inputData.normalWS, light.direction)) * atten * transmissionValue;
        transmissionColor.rgb += albedo * transmission;
    }

    return transmissionColor;
}