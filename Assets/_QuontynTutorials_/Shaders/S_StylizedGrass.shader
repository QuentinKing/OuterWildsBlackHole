Shader "Custom/S_StylizedGrass"
{
    Properties
    {
        _AlbedoTip("Albedo Tip", Color) = (0.4, 0.4, 0.4)
        _AlbedoBase("Albedo Base", Color) = (0.2, 0.2, 0.2)
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
                float4 shadowCoord : TEXCOORD5;
                float2 uv0 : TEXCOORD6;
                float4 lightmapUV : TEXCOORD7;
                float4 fog : TEXCOORD8;
            };

            float3 _AlbedoTip;
            float3 _AlbedoBase;
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

            float _WiggleIntensity;

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


            #include "Assets/_QuontynTutorials_/Shaders/S_StylizedIncludeFunctions.hlsl"

            Varyings vert (Attributes input)
            {
                Varyings output;


                /* Vertex wind animation */
                float2 windSpeeds = float2(0.1, 0.05);
                float2 windIntensities = float2(_WindIntensityMain * input.vertexColor.r, _WindIntensitySecondary * input.vertexColor.r) * 0.3;
                float3 newInputPosition = WindOffsetVertex(input.positionOS.xyz, input.normalOS, _WindDirection, _ColorVariationNoiseMap, windSpeeds, windIntensities);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(newInputPosition);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv0 = input.uv0;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = vertexNormalInput.normalWS;
                output.tangentWS = vertexNormalInput.tangentWS;
                output.bitangentWS = vertexNormalInput.bitangentWS;

                output.shadowCoord = GetShadowCoord(vertexInput);
                output.positionCS = vertexInput.positionCS;

                return output;
            }


            float4 frag(Varyings input) : SV_Target
            {
                /* Texture Samples */
                float4 albedoSample = tex2D(_AlbedoMap, input.uv0 * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw);

                float3 GrassColor = float3(0.0, 0.0, 0.0);
                GrassColor.rgb = lerp(_AlbedoBase, _AlbedoTip, albedoSample.r);
                GrassColor.rgb *= lerp(0.8, 1.0, albedoSample.g);

                float3 hsv = RGB2HSV(GrassColor);
                hsv.r += (albedoSample.b - 0.5) * 0.05;
                GrassColor = HSV2RGB(hsv);

                GrassColor.rgb *= lerp(0.8, 1.0, albedoSample.b);

                clip(albedoSample.a - 0.5);

                // Basic lighting to scale with the main light intensity / color
                Light mainLight = GetMainLight(input.shadowCoord);
                GrassColor *= mainLight.color / 2.0;
                GrassColor *= mainLight.shadowAttenuation;

                return float4(GrassColor, 1.0);
            }
            ENDHLSL
        }

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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float3 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };

            float3 _LightDirection;

            sampler2D _AlbedoMap;
            float4 _AlbedoMap_ST; // Scale and tiling

            sampler2D _ColorVariationNoiseMap;
            float4 _ColorVariationNoiseMap_ST;


            float4 _WindDirection;
            float _WindIntensityMain;
            float _WindIntensitySecondary;

            Varyings ShadowVert(Attributes input)
            {
                Varyings output;

                /* Vertex wind animation */
                float2 windSpeeds = float2(0.1, 0.05);
                float2 windIntensities = float2(_WindIntensityMain * input.vertexColor.r, _WindIntensitySecondary * input.vertexColor.r) * 0.3;
                float3 newInputPosition = WindOffsetVertex(input.positionOS.xyz, input.normalOS, _WindDirection, _ColorVariationNoiseMap, windSpeeds, windIntensities);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(newInputPosition);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv0 = input.uv0;
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(vertexInput.positionWS, vertexNormalInput.normalWS, _LightDirection));

                return output;
            }


            half4 ShadowFrag(Varyings input) : SV_Target
            {
                /* Texture Samples */
                float4 albedoSample = tex2D(_AlbedoMap, input.uv0 * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw);

                clip(albedoSample.a-0.5);

                return 0;
            }

            ENDHLSL
        }

        /* Shadow rendering pass */
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        /* Depth prepass */
        UsePass "Universal Render Pipeline/Lit/DepthOnly"

        /* Meta pass for global illumination */
        UsePass "Universal Render Pipeline/Lit/Meta"
    }
}
