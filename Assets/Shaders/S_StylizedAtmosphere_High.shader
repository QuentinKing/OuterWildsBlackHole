Shader "Custom/S_StylizedAtmosphere_High"
{
    // Cowboy atmosphere shader
    // based on the gpu gems article: https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering

    // I say cowboy cause there is a lot of physical properties that I ignore, most just taking the skeleton of the theory
    // and then tweaking it to get the look I want

    Properties
    {
        _Color("Main Color", Color) = (1.0, 1.0, 1.0)

        _NumSamples("Number of Atmosphere Samples", int) = 10 
        _AtmosphereHeight("Atmosphere Height", float) = 4.0
        _AtmosphereDensityAverage("Average Atmosphgere Density Height", Range(0.0, 1.0)) = 0.25
        _AtmosphereDensityMult("Atmosphere Density Multiplier", float) = 1.0

        _ColorScatteringFactors("Color Scattering Factors (RGB)", float) = (1.0, 1.0, 1.0)

    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderQueue" = "Transparent"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {

            Name "ForwardRendering"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _OCCLUSIONMAP
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 objectScale : TEXCOORD3;
                float3 objectPosition : TEXCOORD4;
            };


            float DoRayAtmosphereIntersection(float3 rayStart, float3 rayDirection, float3 spherePosition, float sphereRadius)
            {
                float t = -1.0f;

                float3 L = spherePosition - rayStart;
                float tca = dot(L, rayDirection);
                if (tca < 0)
                {
                    // No intersection, ray missed
                    return -2.0f;
                }

                float d2 = dot(L, L) - tca * tca;
                float radius2 = sphereRadius * sphereRadius;
                if (d2 > radius2)
                {
                    // No intersection, ray missed
                    return -1.0f;
                }

                float thc = sqrt(radius2 - d2);
                return tca + thc;
            }

            float GetAtmosphereHeight01(float3 atmospherePositionWS, float3 spherePositionWS, float sphereRadius, float atmosphereHeight)
            {
                float distToCenter = length(atmospherePositionWS - spherePositionWS);
                float startAtmosphereHeight = sphereRadius - atmosphereHeight;
                
                float h  = (distToCenter - startAtmosphereHeight) / (sphereRadius - atmosphereHeight);

                return saturate(h);
            }


            float3 _Color;
            float _Alpha;
            
            int _NumSamples;
            float _AtmosphereDensityMult;
            float _AtmosphereHeight;
            float _AtmosphereDensityAverage;
            float3 _ColorScatteringFactors;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                /* Vertex positions in different coordinate spaces */
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                /* Normal space vectors */
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;

                /* UVs */
                output.uv = input.uv.xy;

                /* Object Scale and Position */
                output.objectScale =
                    float3(
                        length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)),
                        length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)),
                        length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))
                        );
                output.objectPosition = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

                return output;
            }

            float OutScatterAlongRay(float3 start, float3 end, Varyings input)
            {
                float rayDelta = length(start - end) / (_NumSamples + 1);
                float3 curPosition = start;
                float3 rayDir = normalize(end - start);

                float scatterTotal = 0;

                for (int i = 0; i < _NumSamples; i++)
                {
                    curPosition += rayDir * rayDelta;

                    float h = GetAtmosphereHeight01(curPosition, input.objectPosition, input.objectScale, _AtmosphereHeight);
                    float density = exp(-h / _AtmosphereDensityAverage);
                    
                    scatterTotal += density * rayDelta;
                }

                return scatterTotal;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float3 cameraWS = _WorldSpaceCameraPos;

                // Find the start of our atmosphere ray, this is either:
                // - The entry point of the atmosphere (if camera is outside the atmosphere)
                // - The current camera position (if camera is inside the atmosphere)
                float3 rayDir = normalize(cameraWS - input.positionWS);
                float3 rayStart = input.positionWS + rayDir * 0.001;

                // The standard ray sphere intersection test. But, we're starting on the edge of the sphere (and slightly inside)
                // SO: we know we want the first solution is going to be a very slightly negative t value.
                // This function returns the second (positive solution, on the other side of the sphere )
                float t = DoRayAtmosphereIntersection(rayStart, rayDir, input.objectPosition, input.objectScale.r);
                float cameraT = length(cameraWS - input.positionWS);

                // t is the depth along the rayDir to the sphere intersection point
                // cameraT is the depth along the rayDir to the location of the camera
                // So, if t < cameraT, that means we are outside of the atmosphere
                //if (t < cameraT) { return float4(1.0, 0.0, 0.0, 1.0); } else { return float4(0.0, 1.0, 0.0, 1.0); }
                float3 atmosphereStart = t < cameraT ? rayStart + t * rayDir : cameraWS;
                float3 atmosphereEnd = input.positionWS;

                // Scattering coefficients
                float3 scatteringCoefficients = pow(1.0 / _ColorScatteringFactors, 4.0);

                float rayDelta = length(atmosphereStart - atmosphereEnd) / (_NumSamples + 1);
                float3 curPosition =  atmosphereEnd;
                float3 toSunDir = _MainLightPosition.xyz;
                float3 lightTotal = float3(0.0, 0.0, 0.0);

                float3 testVal = float3(0.0, 0.0, 0.0);

                for (int i = 0; i < _NumSamples; i++)
                {
                    curPosition += rayDir * rayDelta; // Move along the ray

                    float h = GetAtmosphereHeight01(curPosition, input.objectPosition, input.objectScale, _AtmosphereHeight);

                    // Get exit point along the light ray towards the sun
                    float r = DoRayAtmosphereIntersection(curPosition, toSunDir, input.objectPosition, input.objectScale.r);
                    float3 sunEntryPoint = curPosition + toSunDir * r;
                    float l = OutScatterAlongRay(curPosition, sunEntryPoint, input);

                    // Outscattering across the view ray
                    float v = OutScatterAlongRay(curPosition, atmosphereEnd, input);

                    // Atmosphere density at our curent sample point
                    float density = exp(-(h / _AtmosphereDensityAverage));

                    float3 curLightSample = exp((-l - v) * scatteringCoefficients) * density;

                    // Random tech art hack, since this planet has holes that you can see right through,
                    // I wanna limit the light that scatters in the sightlines where you are looking through the whole planet
                    
                    float inCenter = length(curPosition - input.objectPosition) / (length(input.positionWS - input.objectPosition) - _AtmosphereHeight);
                    inCenter = min(inCenter, 1.0);
                    curLightSample *= pow(inCenter, 16.0);

                    // In scattering, how much light was scattered from the sun direction to our view direction
                    lightTotal += curLightSample;
                }

                float3 lightRGB = normalize(lightTotal * scatteringCoefficients);
                float lightIntensity = length(lightTotal) * _AtmosphereDensityMult;

                return float4(lightRGB, lightIntensity);
            }
            ENDHLSL
        }

        /* Meta pass for global illumination */
        UsePass "Universal Render Pipeline/Lit/Meta"
    }
}
