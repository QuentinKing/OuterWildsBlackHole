Shader "Custom/S_StylizedFoliage"
{
    Properties
    {
        _Albedo("Albedo Color", Color) = (0.4, 0.4, 0.4)
        _AlbedoMap("Albedo Map", 2D) = "white" {}
        _ColorVariationNoiseMap("Color Variation", 2D) = "white" {}

        [Space(30)]_Metallic("Metallic", Range(0 , 1)) = 0
        _Smoothness("Smoothness", Range(0 , 1)) = 0.3
        _Specular("Specular Color", Color) = (1.0, 1.0, 1.0)
        _Occlusion("Occlusion", float) = 1.0
        _Emission("Emission Color", Color) = (0.0, 0.0, 0.0)
        _Alpha("Alpha", float) = 1.0

        [Space(30)]_RimPower("Rim Power", float) = 4.0
        _RimColor("Rim Color", Color) = (1.0, 1.0, 1.0)

        [Space(30)] [Toggle(USE_NORMALMAP)] _UseNormalMap("Use Normal Map?", Int) = 0
        _NormalMap("Normal Map", 2D) = "white" {}
        _NormalMapIntensity("Normal Map Intensity", float) = 1.0

        [Space(30)] _TransmissionIntensity("Transmission Intensity", float) = 0.0
        _ColorVariationIntensity("Color Variation Intensity", float) = 0.0
        _ColorVariationScale("Color Variation Scale", float) = 1.0
        _ColorVariationHueOffset("Color Variation Hue Offset", Range(-0.5, 0.5)) = 0.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
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

            Blend One Zero
            ZWrite On
            ZTest LEqual

            Cull Off

            HLSLPROGRAM



            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0
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

            /* Compile multiple versions of our shader with our custom properties */
            #pragma multi_compile __ USE_NORMALMAP

            #pragma vertex vert
            #pragma fragment frag


            /* UNITY INCLUDES */
            /*
                A bunch of include helper shader functions and structs are defined here. Kind of a mess to figure out
                but you can brute force a lot of it in https://github.com/Unity-Technologies/Graphics
            */

            /*
            struct VertexPositionInputs
            {
                float3 positionWS; // World space position
                float3 positionVS; // View space position
                float4 positionCS; // Homogeneous clip space position
                float4 positionNDC;// Homogeneous normalized device coordinates
            };

            struct VertexNormalInputs
            {
                real3 tangentWS;
                real3 bitangentWS;
                float3 normalWS;
            };

                        struct InputData
            {
                float3  positionWS;
                float4  positionCS;
                half3   normalWS;
                half3   viewDirectionWS;
                float4  shadowCoord;
                half    fogCoord;
                half3   vertexLighting;
                half3   bakedGI;
                float2  normalizedScreenSpaceUV;
                half4   shadowMask;
                half3x3 tangentToWorld;

                #if defined(DEBUG_DISPLAY)
                half2   dynamicLightmapUV;
                half2   staticLightmapUV;
                float3  vertexSH;

                half3 brdfDiffuse;
                half3 brdfSpecular;
                float2 uv;
                uint mipCount;

                // texelSize :
                // x = 1 / width
                // y = 1 / height
                // z = width
                // w = height
                float4 texelSize;

                // mipInfo :
                // x = quality settings minStreamingMipLevel
                // y = original mip count for texture
                // z = desired on screen mip level
                // w = loaded mip level
                float4 mipInfo;
                #endif
            };
            */
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            /* 
                half4 UniversalFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha)
            */
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float3 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 vertexColor : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TECOORD4;
                float2 uv0 : TEXCOORD5;
                float4 lightmapUV : TEXCOORD6;
                float4 fog : TEXCOORD7;
            };

            float3 _Albedo;
            float _Metallic;
            float3 _Specular;
            float _Smoothness;
            float _Occlusion;
            float3 _Emission;
            float _Alpha;
            float _RimPower;
            float3 _RimColor;

            float _TransmissionIntensity;
            float _ColorVariationIntensity;
            float _ColorVariationScale;
            float _ColorVariationHueOffset;

            sampler2D _AlbedoMap;
            float4 _AlbedoMap_ST; // Scale and tiling

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            sampler2D _ColorVariationNoiseMap;
            float4 _ColorVariationNoiseMap_ST;

            float _NormalMapIntensity;

            float4 _WindDirection;
            float _WindIntensityMain;
            float _WindIntensitySecondary;
            float _WindTurbulence;
            float _WiggleIntensity;

            #include "Assets/_QuontynTutorials_/Shaders/S_StylizedIncludeFunctions.hlsl"

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                /* Vertex wind animation */
                float2 windSpeeds = float2(0.1, 0.05);
                float2 windIntensities = float2(_WindIntensityMain * input.vertexColor.r, _WindIntensitySecondary * input.vertexColor.g);
                float3 newInputPosition = WindOffsetVertex(input.positionOS.xyz, input.normalOS, _WindDirection, _ColorVariationNoiseMap, windSpeeds, windIntensities);

                /* Normal space vectors */
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = normalInput.tangentWS;
                output.bitangentWS = normalInput.bitangentWS;

                /* Vertex positions in different coordinate spaces */
                VertexPositionInputs vertexInput = GetVertexPositionInputs(newInputPosition);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                /* UVs */
                output.uv0 = input.uv0;

                /* Lightmap / Spherical Harmonics */
                OUTPUT_LIGHTMAP_UV(input.uv1, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(normalInput.normalWS, output.lightmapUV);

                /* Fog */
                output.fog = ComputeFogFactor(vertexInput.positionCS.z);

                /* Vertex Colors */
                output.vertexColor = input.vertexColor;

                return output;
            }


            float4 frag(Varyings input) : SV_Target
            {
                /* UV Rotation */
                float3 WindDirection = normalize(float3(-0.2, 0.0, -1.0));
                float wiggleAmplitude = TriPlanarMap(_ColorVariationNoiseMap, (input.positionWS.xyz + (WindDirection * _Time * 30.0)) * 0.005, input.normalWS).r;
                wiggleAmplitude -= 0.5; // Remap to [-0.5, 0.5]
                wiggleAmplitude *= _WindTurbulence;
                input.uv0 = float2(cos(wiggleAmplitude) * input.uv0.x + sin(wiggleAmplitude) * input.uv0.y, cos(wiggleAmplitude) * input.uv0.y - sin(wiggleAmplitude) * input.uv0.x);

                /* Texture Samples */
                float4 albedoSample = tex2D(_AlbedoMap, input.uv0 * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw);
                float4 normalSample = tex2D(_NormalMap, input.uv0 * _NormalMap_ST.xy + _NormalMap_ST.zw);

                clip(albedoSample.a - 0.5);

                /* Normal Mapping */
                #ifdef USE_NORMALMAP
                    float3 normal = float3(0.0, 0.0, 0.0);
                    normal.xy = normalSample.wy * 2.0 - 1.0;
                    normal.z = sqrt(1.0 - dot(normal, normal));
                    normal = normalize(normal);

                    float3x3 NormalToWorldTranspose = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                    normal = normalize(mul(normal, NormalToWorldTranspose));
                    normal = lerp(input.normalWS, normal, _NormalMapIntensity);
                #else
                    float3 normal = input.normalWS;
                #endif

                /* Color Variation */
                float3 albedo = _Albedo * albedoSample.rgb;
                float3 hsv = RGB2HSV(albedo.rgb);
                float4 triMap = 1.0 - TriPlanarMap(_ColorVariationNoiseMap, input.positionWS * _ColorVariationScale, normal);
                hsv.r += (triMap.r - 0.5 + _ColorVariationHueOffset) * _ColorVariationIntensity;
                albedo.rgb = HSV2RGB(hsv);

                /* Build input data for unity pbr lighting */
                InputData inputData;
                inputData.positionWS = input.positionWS;
                inputData.positionCS = input.positionCS;
                inputData.normalWS = normalize(normal);
                inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = input.fog.x;

                /* Sample GI */
                float3 SH = SampleSH(inputData.normalWS);
                float3 bakedGI = SAMPLE_GI(input.lightmapUV, SH, inputData.normalWS);
                inputData.bakedGI = float3(0.0, 0.0, 0.0); //bakedGI;

                /* Default unity pbr lighting */
                float4 unityColor = UniversalFragmentPBR(inputData, albedo, _Metallic, _Specular, _Smoothness, _Occlusion, _Emission, _Alpha);

                /* Thin Wall */
                InputData inputDataBack = inputData;
                inputDataBack.normalWS *= -1.0;
                float4 backColor = UniversalFragmentPBR(inputDataBack, albedo, _Metallic, _Specular, _Smoothness, _Occlusion, _Emission, _Alpha);

                /* Add fog */
                unityColor.rgb = MixFog(unityColor.rgb, input.fog.x);

                /* Rim lighting */
                float rim = 1.0 - max(dot(inputData.viewDirectionWS, inputData.normalWS), 0.0);
                unityColor.rgb += min(1.0, pow(rim, _RimPower)) * _RimColor;

                return unityColor;
            }
            ENDHLSL
        }

        /* Custom shadow rendering pass so we can alpha clip it */
        Pass
        {
            Name "ShadowCaster"
            Tags 
            { 
                "LightMode" = "ShadowCaster" 
            }

            HLSLPROGRAM

            #define _NORMAL_DROPOFF_TS 1
            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define _EMISSION
            #define _ALPHATEST_ON 1

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Assets/_QuontynTutorials_/Shaders/S_StylizedIncludeFunctions.hlsl"

            float3 _LightDirection;

            float _WiggleIntensity;

            sampler2D _AlbedoMap;
            float4 _AlbedoMap_ST; // Scale and tiling

            sampler2D _ColorVariationNoiseMap;
            float4 _ColorVariationNoiseMap_ST;


            float4 _WindDirection;
            float _WindIntensityMain;
            float _WindIntensitySecondary;
            float _WindTurbulence;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float3 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 vertexColor : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TECOORD4;
                float2 uv0 : TEXCOORD5;
                float4 lightmapUV : TEXCOORD6;
                float4 fog : TEXCOORD7;
            };

            Varyings ShadowVert(Attributes input)
            {
                Varyings output;

                /* For development mostly, so I don't have to worry about object scale, should optimize out in any real project */
                float3 ObjectScale =
                float3(
                    length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
                    length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
                    length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
                );

                float3 ObjectPosition = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

                /* Vertex wind animation */
                float4 WindDirection = normalize(mul(GetWorldToObjectMatrix(), _WindDirection));

                float windAmplitudeMain = TriPlanarMapVertex(_ColorVariationNoiseMap, (input.positionOS.xyz + ObjectPosition + (_Time * 0.1)) * 0.8, input.normalOS).r;
                float3 windOffsetMain = WindDirection * windAmplitudeMain * _WindIntensityMain * input.vertexColor.r * (1.0 / ObjectScale);

                float windAmplitudeSecondary = TriPlanarMapVertex(_ColorVariationNoiseMap, (input.positionOS.xyz + ObjectPosition + (_Time * 0.05)) * 1.5, input.normalOS).r;
                float3 windOffsetSecondary = WindDirection * windAmplitudeSecondary * _WindIntensitySecondary * input.vertexColor.g * (1.0 / ObjectScale);

                float3 newInputPosition = input.positionOS.xyz + windOffsetMain + windOffsetSecondary;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(newInputPosition);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv0 = input.uv0;
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(vertexInput.positionWS, normalInput.normalWS, _LightDirection));

                return output;
            }

            half4 ShadowFrag(Varyings input) : SV_TARGET
            {
                /* Texture Samples */
                float4 albedoSample = tex2D(_AlbedoMap, input.uv0 * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw);
                
                clip(albedoSample.a - 0.5);

                return 0;
            }

            ENDHLSL
        }

        /* Depth prepass */
        UsePass "Universal Render Pipeline/Lit/DepthOnly"

        /* Meta pass for global illumination */
        UsePass "Universal Render Pipeline/Lit/Meta"
    }
}
