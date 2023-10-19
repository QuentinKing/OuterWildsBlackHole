Shader "SG_BlackHole"
{
    Properties
    {
        _ScreenSpaceScale("_ScreenSpaceScale", Float) = 2
        Vector1_0bb6c794ceb5476bbe1601bd36eb7262("_DistortionExponent", Range(1, 16)) = 4
        _SpherePercentage("_SpherePercentage", Range(0, 1)) = 0.25
                Vector1_e1206881e1244ef4a008548fa38caa6a("_OuterGlowMultiplier", Float) = 1
        Vector1_486f1fcc37a949ffb726a117eab0987a("_OuterGlowExponent", Float) = 4
        Color_f649559c5a534a89a4820a4d0c46d676("_OuterGlowTint", Color) = (1, 1, 1, 0)
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue" = "Transparent"
            "ShaderGraphShader" = "true"
            "ShaderGraphTargetId" = "UniversalUnlitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
            "LightMode" = "UseColorTexture"
        }

        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        // GraphKeywords: <None>

        // Defines

        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS : INTERP0;
             float3 normalWS : INTERP1;
             float3 viewDirectionWS : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

        PackedVaryings PackVaryings(Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
            output.viewDirectionWS.xyz = input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

        Varyings UnpackVaryings(PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
            output.viewDirectionWS = input.viewDirectionWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }


        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
        float Vector1_e1206881e1244ef4a008548fa38caa6a;
        float Vector1_486f1fcc37a949ffb726a117eab0987a;
        float4 Color_f649559c5a534a89a4820a4d0c46d676;
        float _ScreenSpaceScale;
        float _SpherePercentage;
        CBUFFER_END

            // Object and Global properties
            SAMPLER(SamplerState_Linear_Repeat);
            TEXTURE2D(_GrabbedTexture);
            SAMPLER(sampler_GrabbedTexture);
            float4 _GrabbedTexture_TexelSize;

            // Graph Includes
            #include "Assets/Shaders/SF_Raycast.hlsl"

            // -- Property used by ScenePickingPass
            #ifdef SCENEPICKINGPASS
            float4 _SelectionID;
            #endif

            // -- Properties used by SceneSelectionPass
            #ifdef SCENESELECTIONPASS
            int _ObjectId;
            int _PassValue;
            #endif

            // Graph Functions

            void Unity_Subtract_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A - B;
            }

            void Unity_Normalize_float2(float2 In, out float2 Out)
            {
                Out = normalize(In);
            }

            void Unity_Multiply_float_float(float A, float B, out float Out)
            {
                Out = A * B;
            }

            void Unity_DegreesToRadians_float(float In, out float Out)
            {
                Out = radians(In);
            }

            void Unity_Tangent_float(float In, out float Out)
            {
                Out = tan(In);
            }

            void Unity_Distance_float3(float3 A, float3 B, out float Out)
            {
                Out = distance(A, B);
            }

            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }

            void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }

            void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A * B;
            }

            void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A - B;
            }

            void Unity_Normalize_float3(float3 In, out float3 Out)
            {
                Out = normalize(In);
            }

            void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
            {
                Out = dot(A, B);
            }

            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }

            void Unity_Arccosine_float(float In, out float Out)
            {
                Out = acos(In);
            }

            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }

            void Unity_OneMinus_float(float In, out float Out)
            {
                Out = 1 - In;
            }

            void Unity_Power_float(float A, float B, out float Out)
            {
                Out = pow(A, B);
            }

            void Unity_Clamp_float(float In, float Min, float Max, out float Out)
            {
                Out = clamp(In, Min, Max);
            }

            void Unity_Add_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A + B;
            }

            void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
            {
                Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
            {
                Out = A * B;
            }

            void Unity_Add_float4(float4 A, float4 B, out float4 Out)
            {
                Out = A + B;
            }

            void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
            {
                Out = lerp(A, B, T);
            }

            // Custom interpolators pre vertex
            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

            // Graph Vertex
            struct VertexDescription
            {
                float3 Position;
                float3 Normal;
                float3 Tangent;
            };

            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                description.Position = IN.ObjectSpacePosition;
                description.Normal = IN.ObjectSpaceNormal;
                description.Tangent = IN.ObjectSpaceTangent;
                return description;
            }

            // Custom interpolators, pre surface
            #ifdef FEATURES_GRAPH_VERTEX
            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
            {
            return output;
            }
            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
            #endif

            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
                float Alpha;
            };

            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                UnityTexture2D _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0 = UnityBuildTexture2DStructNoScale(_GrabbedTexture);
                float4 _ScreenPosition_51105a22f54e4d17b09afa91db32071a_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                float2 _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPosition_1;
                float2 _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2;
                GetScreenPosition_float(SHADERGRAPH_OBJECT_POSITION, _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPosition_1, _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2);
                float2 _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPosition_1;
                float2 _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2;
                GetScreenPosition_float(IN.WorldSpacePosition, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPosition_1, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2);
                float2 _Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2;
                Unity_Subtract_float2(_GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2, _Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2);
                float2 _Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1;
                Unity_Normalize_float2(_Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2, _Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1);
                float _Float_0858218bbadb4cc28f688cb222045023_Out_0 = 60;
                float _Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2;
                Unity_Multiply_float_float(_Float_0858218bbadb4cc28f688cb222045023_Out_0, 0.5, _Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2);
                float _DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1;
                Unity_DegreesToRadians_float(_Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2, _DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1);
                float _Tangent_d697099132a843598d53fc44f3f54c90_Out_1;
                Unity_Tangent_float(_DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1, _Tangent_d697099132a843598d53fc44f3f54c90_Out_1);
                float _Float_ee7eb256b7d54ae091cd271ab04c6477_Out_0 = 2;
                float _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2;
                Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, _WorldSpaceCameraPos, _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2);
                float _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2;
                Unity_Multiply_float_float(_Float_ee7eb256b7d54ae091cd271ab04c6477_Out_0, _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2, _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2);
                float _Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2;
                Unity_Multiply_float_float(_Tangent_d697099132a843598d53fc44f3f54c90_Out_1, _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2, _Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2);
                float3 _Divide_83f1d10c3d7546548385d5647435e568_Out_2;
                Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                         length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                         length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), (_Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2.xxx), _Divide_83f1d10c3d7546548385d5647435e568_Out_2);
                float _Property_6cae10d9522b436cb4146d7228c68a7a_Out_0 = _ScreenSpaceScale;
                float3 _Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2;
                Unity_Multiply_float3_float3(_Divide_83f1d10c3d7546548385d5647435e568_Out_2, (_Property_6cae10d9522b436cb4146d7228c68a7a_Out_0.xxx), _Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2);
                float2 _Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2;
                Unity_Multiply_float2_float2(_Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1, (_Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2.xy), _Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2);
                float3 _Subtract_7f0599c639db43d48cc59ff866e01213_Out_2;
                Unity_Subtract_float3(_WorldSpaceCameraPos, SHADERGRAPH_OBJECT_POSITION, _Subtract_7f0599c639db43d48cc59ff866e01213_Out_2);
                float3 _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1;
                Unity_Normalize_float3(_Subtract_7f0599c639db43d48cc59ff866e01213_Out_2, _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1);
                float _DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2;
                Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1, _DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2);
                float _Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1;
                Unity_Saturate_float(_DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2, _Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1);
                float _Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1;
                Unity_Arccosine_float(_Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1, _Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1);
                float _Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2;
                Unity_Divide_float(_Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1, 1.57075, _Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2);
                float _OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1;
                Unity_OneMinus_float(_Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2, _OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1);
                float _Property_0ab81713536143a48e05ed2ef1bdd6ca_Out_0 = _SpherePercentage;
                float _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1;
                Unity_OneMinus_float(_Property_0ab81713536143a48e05ed2ef1bdd6ca_Out_0, _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1);
                float _Divide_aab7449732a344818563e747c68a86fd_Out_2;
                Unity_Divide_float(_OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1, _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1, _Divide_aab7449732a344818563e747c68a86fd_Out_2);
                float _Property_36f3e10155e04a81a5bda9271d7a77d2_Out_0 = Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                float _Power_2d1c93be45114f68bdc1accd169c9d66_Out_2;
                Unity_Power_float(_Divide_aab7449732a344818563e747c68a86fd_Out_2, _Property_36f3e10155e04a81a5bda9271d7a77d2_Out_0, _Power_2d1c93be45114f68bdc1accd169c9d66_Out_2);
                float3 _Multiply_7848de06422741ff96e8906ad1c95f21_Out_2;
                Unity_Multiply_float3_float3(IN.WorldSpaceViewDirection, float3(-1, -1, -1), _Multiply_7848de06422741ff96e8906ad1c95f21_Out_2);
                float3 _Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2;
                Unity_Subtract_float3(SHADERGRAPH_OBJECT_POSITION, _WorldSpaceCameraPos, _Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2);
                float3 _Normalize_166734be3f694661b28e2eced2e7107a_Out_1;
                Unity_Normalize_float3(_Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2, _Normalize_166734be3f694661b28e2eced2e7107a_Out_1);
                float _DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2;
                Unity_DotProduct_float3(_Multiply_7848de06422741ff96e8906ad1c95f21_Out_2, _Normalize_166734be3f694661b28e2eced2e7107a_Out_1, _DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2);
                float _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3;
                Unity_Clamp_float(_DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2, 0, 1, _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3);
                float _Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2;
                Unity_Multiply_float_float(_Power_2d1c93be45114f68bdc1accd169c9d66_Out_2, _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3, _Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2);
                float2 _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2;
                Unity_Multiply_float2_float2(_Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2, (_Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2.xx), _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2);
                float2 _Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2;
                Unity_Add_float2((_ScreenPosition_51105a22f54e4d17b09afa91db32071a_Out_0.xy), _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2, _Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2);
                float2 _MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1;
                MirrorUVCoordinates_float(_Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2, _MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1);
                float4 _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.tex, _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.samplerstate, _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.GetTransformedUV(_MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1));
                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_R_4 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.r;
                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_G_5 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.g;
                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_B_6 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.b;
                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_A_7 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.a;
                float3 _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1;
                Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1);
                float _Property_4c613d3b075447e1a3665e411e69b0c0_Out_0 = _SpherePercentage;
                float3 _Multiply_51944a57b67f4483b3d1cb938905510b_Out_2;
                Unity_Multiply_float3_float3((_Property_4c613d3b075447e1a3665e411e69b0c0_Out_0.xxx), float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                         length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                         length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_51944a57b67f4483b3d1cb938905510b_Out_2);
                float _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4;
                float3 _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitPosition_5;
                float3 _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6;
                Raycast_float(_WorldSpaceCameraPos, _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1, SHADERGRAPH_OBJECT_POSITION, (_Multiply_51944a57b67f4483b3d1cb938905510b_Out_2).x, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitPosition_5, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6);
                float _OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1;
                Unity_OneMinus_float(_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4, _OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1);
                float4 _Property_85c759db8b2244fea01e7b592f2c2543_Out_0 = Color_f649559c5a534a89a4820a4d0c46d676;
                float _Property_d12b7c94c2834ff89b28eec2f4d5ee63_Out_0 = Vector1_486f1fcc37a949ffb726a117eab0987a;
                float _FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3;
                Unity_FresnelEffect_float(_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6, IN.WorldSpaceViewDirection, _Property_d12b7c94c2834ff89b28eec2f4d5ee63_Out_0, _FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3);
                float _Property_fde8720b3dd647c7b469ace795991409_Out_0 = Vector1_e1206881e1244ef4a008548fa38caa6a;
                float _Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2;
                Unity_Multiply_float_float(_FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3, _Property_fde8720b3dd647c7b469ace795991409_Out_0, _Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2);
                float4 _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2;
                Unity_Multiply_float4_float4(_Property_85c759db8b2244fea01e7b592f2c2543_Out_0, (_Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2.xxxx), _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2);
                float4 _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2;
                Unity_Add_float4((_OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1.xxxx), _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2, _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2);
                float4 _Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3;
                Unity_Lerp_float4(_SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0, _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2, (_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4.xxxx), _Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3);
                surface.BaseColor = (_Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3.xyz);
                surface.Alpha = 1;
                return surface;
            }

            // --------------------------------------------------
            // Build Graph Inputs
            #ifdef HAVE_VFX_MODIFICATION
            #define VFX_SRP_ATTRIBUTES Attributes
            #define VFX_SRP_VARYINGS Varyings
            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
            #endif
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                output.ObjectSpaceNormal = input.normalOS;
                output.ObjectSpaceTangent = input.tangentOS.xyz;
                output.ObjectSpacePosition = input.positionOS;

                return output;
            }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

            #ifdef HAVE_VFX_MODIFICATION
                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

            #endif



                // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                float3 unnormalizedNormalWS = input.normalWS;
                const float renormFactor = 1.0 / length(unnormalizedNormalWS);


                output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph


                output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
                output.WorldSpacePosition = input.positionWS;
                output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                    return output;
            }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"

            // --------------------------------------------------
            // Visual Effect Vertex Invocations
            #ifdef HAVE_VFX_MODIFICATION
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
            #endif

            ENDHLSL
            }
            Pass
            {
                Name "DepthNormalsOnly"
                Tags
                {
                    "LightMode" = "DepthNormalsOnly"
                }

                // Render State
                Cull Back
                ZTest LEqual
                ZWrite On

                // Debug
                // <None>

                // --------------------------------------------------
                // Pass

                HLSLPROGRAM

                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag

                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>

                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>

                // Defines

                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                // custom interpolator pre-include
                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                // --------------------------------------------------
                // Structs and Packing

                // custom interpolators pre packing
                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                struct Attributes
                {
                     float3 positionOS : POSITION;
                     float3 normalOS : NORMAL;
                     float4 tangentOS : TANGENT;
                     float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                     uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                     float4 positionCS : SV_POSITION;
                     float3 normalWS;
                     float4 tangentWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                     uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
                     float4 tangentWS : INTERP0;
                     float3 normalWS : INTERP1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                     uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };

                PackedVaryings PackVaryings(Varyings input)
                {
                    PackedVaryings output;
                    ZERO_INITIALIZE(PackedVaryings, output);
                    output.positionCS = input.positionCS;
                    output.tangentWS.xyzw = input.tangentWS;
                    output.normalWS.xyz = input.normalWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }

                Varyings UnpackVaryings(PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.tangentWS = input.tangentWS.xyzw;
                    output.normalWS = input.normalWS.xyz;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }


                // --------------------------------------------------
                // Graph

                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                float _ScreenSpaceScale;
                float _SpherePercentage;
                CBUFFER_END

                    // Object and Global properties
                    SAMPLER(SamplerState_Linear_Repeat);
                    TEXTURE2D(_GrabbedTexture);
                    SAMPLER(sampler_GrabbedTexture);
                    float4 _GrabbedTexture_TexelSize;

                    // Graph Includes
                    // GraphIncludes: <None>

                    // -- Property used by ScenePickingPass
                    #ifdef SCENEPICKINGPASS
                    float4 _SelectionID;
                    #endif

                    // -- Properties used by SceneSelectionPass
                    #ifdef SCENESELECTIONPASS
                    int _ObjectId;
                    int _PassValue;
                    #endif

                    // Graph Functions
                    // GraphFunctions: <None>

                    // Custom interpolators pre vertex
                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                    // Graph Vertex
                    struct VertexDescription
                    {
                        float3 Position;
                        float3 Normal;
                        float3 Tangent;
                    };

                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        description.Position = IN.ObjectSpacePosition;
                        description.Normal = IN.ObjectSpaceNormal;
                        description.Tangent = IN.ObjectSpaceTangent;
                        return description;
                    }

                    // Custom interpolators, pre surface
                    #ifdef FEATURES_GRAPH_VERTEX
                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                    {
                    return output;
                    }
                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                    #endif

                    // Graph Pixel
                    struct SurfaceDescription
                    {
                        float Alpha;
                    };

                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        surface.Alpha = 1;
                        return surface;
                    }

                    // --------------------------------------------------
                    // Build Graph Inputs
                    #ifdef HAVE_VFX_MODIFICATION
                    #define VFX_SRP_ATTRIBUTES Attributes
                    #define VFX_SRP_VARYINGS Varyings
                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                    #endif
                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                    {
                        VertexDescriptionInputs output;
                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                        output.ObjectSpaceNormal = input.normalOS;
                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                        output.ObjectSpacePosition = input.positionOS;

                        return output;
                    }
                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                    {
                        SurfaceDescriptionInputs output;
                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                    #ifdef HAVE_VFX_MODIFICATION
                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                    #endif







                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                    #else
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                    #endif
                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                            return output;
                    }

                    // --------------------------------------------------
                    // Main

                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                    // --------------------------------------------------
                    // Visual Effect Vertex Invocations
                    #ifdef HAVE_VFX_MODIFICATION
                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                    #endif

                    ENDHLSL
                    }
                    Pass
                    {
                        Name "ShadowCaster"
                        Tags
                        {
                            "LightMode" = "ShadowCaster"
                        }

                        // Render State
                        Cull Back
                        ZTest LEqual
                        ZWrite On
                        ColorMask 0

                        // Debug
                        // <None>

                        // --------------------------------------------------
                        // Pass

                        HLSLPROGRAM

                        // Pragmas
                        #pragma target 4.5
                        #pragma exclude_renderers gles gles3 glcore
                        #pragma multi_compile_instancing
                        #pragma multi_compile _ DOTS_INSTANCING_ON
                        #pragma vertex vert
                        #pragma fragment frag

                        // DotsInstancingOptions: <None>
                        // HybridV1InjectedBuiltinProperties: <None>

                        // Keywords
                        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
                        // GraphKeywords: <None>

                        // Defines

                        #define ATTRIBUTES_NEED_NORMAL
                        #define ATTRIBUTES_NEED_TANGENT
                        #define VARYINGS_NEED_NORMAL_WS
                        #define FEATURES_GRAPH_VERTEX
                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                        #define SHADERPASS SHADERPASS_SHADOWCASTER
                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                        // custom interpolator pre-include
                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                        // Includes
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                        // --------------------------------------------------
                        // Structs and Packing

                        // custom interpolators pre packing
                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                        struct Attributes
                        {
                             float3 positionOS : POSITION;
                             float3 normalOS : NORMAL;
                             float4 tangentOS : TANGENT;
                            #if UNITY_ANY_INSTANCING_ENABLED
                             uint instanceID : INSTANCEID_SEMANTIC;
                            #endif
                        };
                        struct Varyings
                        {
                             float4 positionCS : SV_POSITION;
                             float3 normalWS;
                            #if UNITY_ANY_INSTANCING_ENABLED
                             uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                        };
                        struct SurfaceDescriptionInputs
                        {
                        };
                        struct VertexDescriptionInputs
                        {
                             float3 ObjectSpaceNormal;
                             float3 ObjectSpaceTangent;
                             float3 ObjectSpacePosition;
                        };
                        struct PackedVaryings
                        {
                             float4 positionCS : SV_POSITION;
                             float3 normalWS : INTERP0;
                            #if UNITY_ANY_INSTANCING_ENABLED
                             uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                        };

                        PackedVaryings PackVaryings(Varyings input)
                        {
                            PackedVaryings output;
                            ZERO_INITIALIZE(PackedVaryings, output);
                            output.positionCS = input.positionCS;
                            output.normalWS.xyz = input.normalWS;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }

                        Varyings UnpackVaryings(PackedVaryings input)
                        {
                            Varyings output;
                            output.positionCS = input.positionCS;
                            output.normalWS = input.normalWS.xyz;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }


                        // --------------------------------------------------
                        // Graph

                        // Graph Properties
                        CBUFFER_START(UnityPerMaterial)
                        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                        float Vector1_e1206881e1244ef4a008548fa38caa6a;
                        float Vector1_486f1fcc37a949ffb726a117eab0987a;
                        float4 Color_f649559c5a534a89a4820a4d0c46d676;
                        float _ScreenSpaceScale;
                        float _SpherePercentage;
                        CBUFFER_END

                            // Object and Global properties
                            SAMPLER(SamplerState_Linear_Repeat);
                            TEXTURE2D(_GrabbedTexture);
                            SAMPLER(sampler_GrabbedTexture);
                            float4 _GrabbedTexture_TexelSize;

                            // Graph Includes
                            // GraphIncludes: <None>

                            // -- Property used by ScenePickingPass
                            #ifdef SCENEPICKINGPASS
                            float4 _SelectionID;
                            #endif

                            // -- Properties used by SceneSelectionPass
                            #ifdef SCENESELECTIONPASS
                            int _ObjectId;
                            int _PassValue;
                            #endif

                            // Graph Functions
                            // GraphFunctions: <None>

                            // Custom interpolators pre vertex
                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                            // Graph Vertex
                            struct VertexDescription
                            {
                                float3 Position;
                                float3 Normal;
                                float3 Tangent;
                            };

                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                            {
                                VertexDescription description = (VertexDescription)0;
                                description.Position = IN.ObjectSpacePosition;
                                description.Normal = IN.ObjectSpaceNormal;
                                description.Tangent = IN.ObjectSpaceTangent;
                                return description;
                            }

                            // Custom interpolators, pre surface
                            #ifdef FEATURES_GRAPH_VERTEX
                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                            {
                            return output;
                            }
                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                            #endif

                            // Graph Pixel
                            struct SurfaceDescription
                            {
                                float Alpha;
                            };

                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                            {
                                SurfaceDescription surface = (SurfaceDescription)0;
                                surface.Alpha = 1;
                                return surface;
                            }

                            // --------------------------------------------------
                            // Build Graph Inputs
                            #ifdef HAVE_VFX_MODIFICATION
                            #define VFX_SRP_ATTRIBUTES Attributes
                            #define VFX_SRP_VARYINGS Varyings
                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                            #endif
                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                            {
                                VertexDescriptionInputs output;
                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                output.ObjectSpaceNormal = input.normalOS;
                                output.ObjectSpaceTangent = input.tangentOS.xyz;
                                output.ObjectSpacePosition = input.positionOS;

                                return output;
                            }
                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                            {
                                SurfaceDescriptionInputs output;
                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                            #ifdef HAVE_VFX_MODIFICATION
                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                            #endif







                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                            #else
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                            #endif
                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                    return output;
                            }

                            // --------------------------------------------------
                            // Main

                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

                            // --------------------------------------------------
                            // Visual Effect Vertex Invocations
                            #ifdef HAVE_VFX_MODIFICATION
                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                            #endif

                            ENDHLSL
                            }
                            Pass
                            {
                                Name "SceneSelectionPass"
                                Tags
                                {
                                    "LightMode" = "SceneSelectionPass"
                                }

                                // Render State
                                Cull Off

                                // Debug
                                // <None>

                                // --------------------------------------------------
                                // Pass

                                HLSLPROGRAM

                                // Pragmas
                                #pragma target 4.5
                                #pragma exclude_renderers gles gles3 glcore
                                #pragma vertex vert
                                #pragma fragment frag

                                // DotsInstancingOptions: <None>
                                // HybridV1InjectedBuiltinProperties: <None>

                                // Keywords
                                // PassKeywords: <None>
                                // GraphKeywords: <None>

                                // Defines

                                #define ATTRIBUTES_NEED_NORMAL
                                #define ATTRIBUTES_NEED_TANGENT
                                #define FEATURES_GRAPH_VERTEX
                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                #define SHADERPASS SHADERPASS_DEPTHONLY
                                #define SCENESELECTIONPASS 1
                                #define ALPHA_CLIP_THRESHOLD 1
                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                // custom interpolator pre-include
                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                // Includes
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                // --------------------------------------------------
                                // Structs and Packing

                                // custom interpolators pre packing
                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                struct Attributes
                                {
                                     float3 positionOS : POSITION;
                                     float3 normalOS : NORMAL;
                                     float4 tangentOS : TANGENT;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                     uint instanceID : INSTANCEID_SEMANTIC;
                                    #endif
                                };
                                struct Varyings
                                {
                                     float4 positionCS : SV_POSITION;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                };
                                struct SurfaceDescriptionInputs
                                {
                                };
                                struct VertexDescriptionInputs
                                {
                                     float3 ObjectSpaceNormal;
                                     float3 ObjectSpaceTangent;
                                     float3 ObjectSpacePosition;
                                };
                                struct PackedVaryings
                                {
                                     float4 positionCS : SV_POSITION;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                };

                                PackedVaryings PackVaryings(Varyings input)
                                {
                                    PackedVaryings output;
                                    ZERO_INITIALIZE(PackedVaryings, output);
                                    output.positionCS = input.positionCS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }

                                Varyings UnpackVaryings(PackedVaryings input)
                                {
                                    Varyings output;
                                    output.positionCS = input.positionCS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }


                                // --------------------------------------------------
                                // Graph

                                // Graph Properties
                                CBUFFER_START(UnityPerMaterial)
                                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                float _ScreenSpaceScale;
                                float _SpherePercentage;
                                CBUFFER_END

                                    // Object and Global properties
                                    SAMPLER(SamplerState_Linear_Repeat);
                                    TEXTURE2D(_GrabbedTexture);
                                    SAMPLER(sampler_GrabbedTexture);
                                    float4 _GrabbedTexture_TexelSize;

                                    // Graph Includes
                                    // GraphIncludes: <None>

                                    // -- Property used by ScenePickingPass
                                    #ifdef SCENEPICKINGPASS
                                    float4 _SelectionID;
                                    #endif

                                    // -- Properties used by SceneSelectionPass
                                    #ifdef SCENESELECTIONPASS
                                    int _ObjectId;
                                    int _PassValue;
                                    #endif

                                    // Graph Functions
                                    // GraphFunctions: <None>

                                    // Custom interpolators pre vertex
                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                    // Graph Vertex
                                    struct VertexDescription
                                    {
                                        float3 Position;
                                        float3 Normal;
                                        float3 Tangent;
                                    };

                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                    {
                                        VertexDescription description = (VertexDescription)0;
                                        description.Position = IN.ObjectSpacePosition;
                                        description.Normal = IN.ObjectSpaceNormal;
                                        description.Tangent = IN.ObjectSpaceTangent;
                                        return description;
                                    }

                                    // Custom interpolators, pre surface
                                    #ifdef FEATURES_GRAPH_VERTEX
                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                    {
                                    return output;
                                    }
                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                    #endif

                                    // Graph Pixel
                                    struct SurfaceDescription
                                    {
                                        float Alpha;
                                    };

                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                    {
                                        SurfaceDescription surface = (SurfaceDescription)0;
                                        surface.Alpha = 1;
                                        return surface;
                                    }

                                    // --------------------------------------------------
                                    // Build Graph Inputs
                                    #ifdef HAVE_VFX_MODIFICATION
                                    #define VFX_SRP_ATTRIBUTES Attributes
                                    #define VFX_SRP_VARYINGS Varyings
                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                    #endif
                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                    {
                                        VertexDescriptionInputs output;
                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                        output.ObjectSpaceNormal = input.normalOS;
                                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                                        output.ObjectSpacePosition = input.positionOS;

                                        return output;
                                    }
                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                    {
                                        SurfaceDescriptionInputs output;
                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                    #ifdef HAVE_VFX_MODIFICATION
                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                    #endif







                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                    #else
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                    #endif
                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                            return output;
                                    }

                                    // --------------------------------------------------
                                    // Main

                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                    // --------------------------------------------------
                                    // Visual Effect Vertex Invocations
                                    #ifdef HAVE_VFX_MODIFICATION
                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                    #endif

                                    ENDHLSL
                                    }
                                    Pass
                                    {
                                        Name "ScenePickingPass"
                                        Tags
                                        {
                                            "LightMode" = "Picking"
                                        }

                                        // Render State
                                        Cull Back

                                        // Debug
                                        // <None>

                                        // --------------------------------------------------
                                        // Pass

                                        HLSLPROGRAM

                                        // Pragmas
                                        #pragma target 4.5
                                        #pragma exclude_renderers gles gles3 glcore
                                        #pragma vertex vert
                                        #pragma fragment frag

                                        // DotsInstancingOptions: <None>
                                        // HybridV1InjectedBuiltinProperties: <None>

                                        // Keywords
                                        // PassKeywords: <None>
                                        // GraphKeywords: <None>

                                        // Defines

                                        #define ATTRIBUTES_NEED_NORMAL
                                        #define ATTRIBUTES_NEED_TANGENT
                                        #define FEATURES_GRAPH_VERTEX
                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                        #define SHADERPASS SHADERPASS_DEPTHONLY
                                        #define SCENEPICKINGPASS 1
                                        #define ALPHA_CLIP_THRESHOLD 1
                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                        // custom interpolator pre-include
                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                        // Includes
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                        // --------------------------------------------------
                                        // Structs and Packing

                                        // custom interpolators pre packing
                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                        struct Attributes
                                        {
                                             float3 positionOS : POSITION;
                                             float3 normalOS : NORMAL;
                                             float4 tangentOS : TANGENT;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                             uint instanceID : INSTANCEID_SEMANTIC;
                                            #endif
                                        };
                                        struct Varyings
                                        {
                                             float4 positionCS : SV_POSITION;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                        };
                                        struct SurfaceDescriptionInputs
                                        {
                                        };
                                        struct VertexDescriptionInputs
                                        {
                                             float3 ObjectSpaceNormal;
                                             float3 ObjectSpaceTangent;
                                             float3 ObjectSpacePosition;
                                        };
                                        struct PackedVaryings
                                        {
                                             float4 positionCS : SV_POSITION;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                        };

                                        PackedVaryings PackVaryings(Varyings input)
                                        {
                                            PackedVaryings output;
                                            ZERO_INITIALIZE(PackedVaryings, output);
                                            output.positionCS = input.positionCS;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }

                                        Varyings UnpackVaryings(PackedVaryings input)
                                        {
                                            Varyings output;
                                            output.positionCS = input.positionCS;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }


                                        // --------------------------------------------------
                                        // Graph

                                        // Graph Properties
                                        CBUFFER_START(UnityPerMaterial)
                                        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                        float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                        float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                        float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                        float _ScreenSpaceScale;
                                        float _SpherePercentage;
                                        CBUFFER_END

                                            // Object and Global properties
                                            SAMPLER(SamplerState_Linear_Repeat);
                                            TEXTURE2D(_GrabbedTexture);
                                            SAMPLER(sampler_GrabbedTexture);
                                            float4 _GrabbedTexture_TexelSize;

                                            // Graph Includes
                                            // GraphIncludes: <None>

                                            // -- Property used by ScenePickingPass
                                            #ifdef SCENEPICKINGPASS
                                            float4 _SelectionID;
                                            #endif

                                            // -- Properties used by SceneSelectionPass
                                            #ifdef SCENESELECTIONPASS
                                            int _ObjectId;
                                            int _PassValue;
                                            #endif

                                            // Graph Functions
                                            // GraphFunctions: <None>

                                            // Custom interpolators pre vertex
                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                            // Graph Vertex
                                            struct VertexDescription
                                            {
                                                float3 Position;
                                                float3 Normal;
                                                float3 Tangent;
                                            };

                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                            {
                                                VertexDescription description = (VertexDescription)0;
                                                description.Position = IN.ObjectSpacePosition;
                                                description.Normal = IN.ObjectSpaceNormal;
                                                description.Tangent = IN.ObjectSpaceTangent;
                                                return description;
                                            }

                                            // Custom interpolators, pre surface
                                            #ifdef FEATURES_GRAPH_VERTEX
                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                            {
                                            return output;
                                            }
                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                            #endif

                                            // Graph Pixel
                                            struct SurfaceDescription
                                            {
                                                float Alpha;
                                            };

                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                            {
                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                surface.Alpha = 1;
                                                return surface;
                                            }

                                            // --------------------------------------------------
                                            // Build Graph Inputs
                                            #ifdef HAVE_VFX_MODIFICATION
                                            #define VFX_SRP_ATTRIBUTES Attributes
                                            #define VFX_SRP_VARYINGS Varyings
                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                            #endif
                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                            {
                                                VertexDescriptionInputs output;
                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                output.ObjectSpaceNormal = input.normalOS;
                                                output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                output.ObjectSpacePosition = input.positionOS;

                                                return output;
                                            }
                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                            {
                                                SurfaceDescriptionInputs output;
                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                            #ifdef HAVE_VFX_MODIFICATION
                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                            #endif







                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                            #else
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                            #endif
                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                    return output;
                                            }

                                            // --------------------------------------------------
                                            // Main

                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                            // --------------------------------------------------
                                            // Visual Effect Vertex Invocations
                                            #ifdef HAVE_VFX_MODIFICATION
                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                            #endif

                                            ENDHLSL
                                            }
                                            Pass
                                            {
                                                Name "DepthNormals"
                                                Tags
                                                {
                                                    "LightMode" = "DepthNormalsOnly"
                                                }

                                                // Render State
                                                Cull Back
                                                ZTest LEqual
                                                ZWrite On

                                                // Debug
                                                // <None>

                                                // --------------------------------------------------
                                                // Pass

                                                HLSLPROGRAM

                                                // Pragmas
                                                #pragma target 4.5
                                                #pragma exclude_renderers gles gles3 glcore
                                                #pragma multi_compile_instancing
                                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                                #pragma vertex vert
                                                #pragma fragment frag

                                                // DotsInstancingOptions: <None>
                                                // HybridV1InjectedBuiltinProperties: <None>

                                                // Keywords
                                                // PassKeywords: <None>
                                                // GraphKeywords: <None>

                                                // Defines

                                                #define ATTRIBUTES_NEED_NORMAL
                                                #define ATTRIBUTES_NEED_TANGENT
                                                #define VARYINGS_NEED_NORMAL_WS
                                                #define FEATURES_GRAPH_VERTEX
                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                                                #define _SURFACE_TYPE_TRANSPARENT 1
                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                // custom interpolator pre-include
                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                // Includes
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                // --------------------------------------------------
                                                // Structs and Packing

                                                // custom interpolators pre packing
                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                struct Attributes
                                                {
                                                     float3 positionOS : POSITION;
                                                     float3 normalOS : NORMAL;
                                                     float4 tangentOS : TANGENT;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                    #endif
                                                };
                                                struct Varyings
                                                {
                                                     float4 positionCS : SV_POSITION;
                                                     float3 normalWS;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                };
                                                struct SurfaceDescriptionInputs
                                                {
                                                };
                                                struct VertexDescriptionInputs
                                                {
                                                     float3 ObjectSpaceNormal;
                                                     float3 ObjectSpaceTangent;
                                                     float3 ObjectSpacePosition;
                                                };
                                                struct PackedVaryings
                                                {
                                                     float4 positionCS : SV_POSITION;
                                                     float3 normalWS : INTERP0;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                };

                                                PackedVaryings PackVaryings(Varyings input)
                                                {
                                                    PackedVaryings output;
                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                    output.positionCS = input.positionCS;
                                                    output.normalWS.xyz = input.normalWS;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }

                                                Varyings UnpackVaryings(PackedVaryings input)
                                                {
                                                    Varyings output;
                                                    output.positionCS = input.positionCS;
                                                    output.normalWS = input.normalWS.xyz;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }


                                                // --------------------------------------------------
                                                // Graph

                                                // Graph Properties
                                                CBUFFER_START(UnityPerMaterial)
                                                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                float _ScreenSpaceScale;
                                                float _SpherePercentage;
                                                CBUFFER_END

                                                    // Object and Global properties
                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                    TEXTURE2D(_GrabbedTexture);
                                                    SAMPLER(sampler_GrabbedTexture);
                                                    float4 _GrabbedTexture_TexelSize;

                                                    // Graph Includes
                                                    // GraphIncludes: <None>

                                                    // -- Property used by ScenePickingPass
                                                    #ifdef SCENEPICKINGPASS
                                                    float4 _SelectionID;
                                                    #endif

                                                    // -- Properties used by SceneSelectionPass
                                                    #ifdef SCENESELECTIONPASS
                                                    int _ObjectId;
                                                    int _PassValue;
                                                    #endif

                                                    // Graph Functions
                                                    // GraphFunctions: <None>

                                                    // Custom interpolators pre vertex
                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                    // Graph Vertex
                                                    struct VertexDescription
                                                    {
                                                        float3 Position;
                                                        float3 Normal;
                                                        float3 Tangent;
                                                    };

                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                    {
                                                        VertexDescription description = (VertexDescription)0;
                                                        description.Position = IN.ObjectSpacePosition;
                                                        description.Normal = IN.ObjectSpaceNormal;
                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                        return description;
                                                    }

                                                    // Custom interpolators, pre surface
                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                    {
                                                    return output;
                                                    }
                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                    #endif

                                                    // Graph Pixel
                                                    struct SurfaceDescription
                                                    {
                                                        float Alpha;
                                                    };

                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                    {
                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                        surface.Alpha = 1;
                                                        return surface;
                                                    }

                                                    // --------------------------------------------------
                                                    // Build Graph Inputs
                                                    #ifdef HAVE_VFX_MODIFICATION
                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                    #define VFX_SRP_VARYINGS Varyings
                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                    #endif
                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                    {
                                                        VertexDescriptionInputs output;
                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                        output.ObjectSpaceNormal = input.normalOS;
                                                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                        output.ObjectSpacePosition = input.positionOS;

                                                        return output;
                                                    }
                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                    {
                                                        SurfaceDescriptionInputs output;
                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                    #ifdef HAVE_VFX_MODIFICATION
                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                    #endif







                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                    #else
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                    #endif
                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                            return output;
                                                    }

                                                    // --------------------------------------------------
                                                    // Main

                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                                                    // --------------------------------------------------
                                                    // Visual Effect Vertex Invocations
                                                    #ifdef HAVE_VFX_MODIFICATION
                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                    #endif

                                                    ENDHLSL
                                                    }
    }
        SubShader
                                                    {
                                                        Tags
                                                        {
                                                            "RenderPipeline" = "UniversalPipeline"
                                                            "RenderType" = "Transparent"
                                                            "UniversalMaterialType" = "Unlit"
                                                            "Queue" = "Transparent"
                                                            "ShaderGraphShader" = "true"
                                                            "ShaderGraphTargetId" = "UniversalUnlitSubTarget"
                                                        }
                                                        Pass
                                                        {
                                                            Name "Universal Forward"
                                                            Tags
                                                            {
                                                            "LightMode" = "UseColorTexture"
                                                        }

                                                        // Render State
                                                        Cull Back
                                                        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                                                        ZTest LEqual
                                                        ZWrite Off

                                                        // Debug
                                                        // <None>

                                                        // --------------------------------------------------
                                                        // Pass

                                                        HLSLPROGRAM

                                                        // Pragmas
                                                        #pragma target 2.0
                                                        #pragma only_renderers gles gles3 glcore d3d11
                                                        #pragma multi_compile_instancing
                                                        #pragma multi_compile_fog
                                                        #pragma instancing_options renderinglayer
                                                        #pragma vertex vert
                                                        #pragma fragment frag

                                                        // DotsInstancingOptions: <None>
                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                        // Keywords
                                                        #pragma multi_compile _ LIGHTMAP_ON
                                                        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                                                        #pragma shader_feature _ _SAMPLE_GI
                                                        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
                                                        #pragma multi_compile_fragment _ DEBUG_DISPLAY
                                                        // GraphKeywords: <None>

                                                        // Defines

                                                        #define ATTRIBUTES_NEED_NORMAL
                                                        #define ATTRIBUTES_NEED_TANGENT
                                                        #define VARYINGS_NEED_POSITION_WS
                                                        #define VARYINGS_NEED_NORMAL_WS
                                                        #define VARYINGS_NEED_VIEWDIRECTION_WS
                                                        #define FEATURES_GRAPH_VERTEX
                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                        #define SHADERPASS SHADERPASS_UNLIT
                                                        #define _FOG_FRAGMENT 1
                                                        #define _SURFACE_TYPE_TRANSPARENT 1
                                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                        // custom interpolator pre-include
                                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                        // Includes
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                        // --------------------------------------------------
                                                        // Structs and Packing

                                                        // custom interpolators pre packing
                                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                        struct Attributes
                                                        {
                                                             float3 positionOS : POSITION;
                                                             float3 normalOS : NORMAL;
                                                             float4 tangentOS : TANGENT;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                             uint instanceID : INSTANCEID_SEMANTIC;
                                                            #endif
                                                        };
                                                        struct Varyings
                                                        {
                                                             float4 positionCS : SV_POSITION;
                                                             float3 positionWS;
                                                             float3 normalWS;
                                                             float3 viewDirectionWS;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                            #endif
                                                        };
                                                        struct SurfaceDescriptionInputs
                                                        {
                                                             float3 WorldSpaceNormal;
                                                             float3 WorldSpaceViewDirection;
                                                             float3 WorldSpacePosition;
                                                             float4 ScreenPosition;
                                                        };
                                                        struct VertexDescriptionInputs
                                                        {
                                                             float3 ObjectSpaceNormal;
                                                             float3 ObjectSpaceTangent;
                                                             float3 ObjectSpacePosition;
                                                        };
                                                        struct PackedVaryings
                                                        {
                                                             float4 positionCS : SV_POSITION;
                                                             float3 positionWS : INTERP0;
                                                             float3 normalWS : INTERP1;
                                                             float3 viewDirectionWS : INTERP2;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                            #endif
                                                        };

                                                        PackedVaryings PackVaryings(Varyings input)
                                                        {
                                                            PackedVaryings output;
                                                            ZERO_INITIALIZE(PackedVaryings, output);
                                                            output.positionCS = input.positionCS;
                                                            output.positionWS.xyz = input.positionWS;
                                                            output.normalWS.xyz = input.normalWS;
                                                            output.viewDirectionWS.xyz = input.viewDirectionWS;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            output.instanceID = input.instanceID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            output.cullFace = input.cullFace;
                                                            #endif
                                                            return output;
                                                        }

                                                        Varyings UnpackVaryings(PackedVaryings input)
                                                        {
                                                            Varyings output;
                                                            output.positionCS = input.positionCS;
                                                            output.positionWS = input.positionWS.xyz;
                                                            output.normalWS = input.normalWS.xyz;
                                                            output.viewDirectionWS = input.viewDirectionWS.xyz;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            output.instanceID = input.instanceID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            output.cullFace = input.cullFace;
                                                            #endif
                                                            return output;
                                                        }


                                                        // --------------------------------------------------
                                                        // Graph

                                                        // Graph Properties
                                                        CBUFFER_START(UnityPerMaterial)
                                                        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                        float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                        float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                        float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                        float _ScreenSpaceScale;
                                                        float _SpherePercentage;
                                                        CBUFFER_END

                                                            // Object and Global properties
                                                            SAMPLER(SamplerState_Linear_Repeat);
                                                            TEXTURE2D(_GrabbedTexture);
                                                            SAMPLER(sampler_GrabbedTexture);
                                                            float4 _GrabbedTexture_TexelSize;

                                                            // Graph Includes
                                                            #include "Assets/Shaders/SF_Raycast.hlsl"

                                                            // -- Property used by ScenePickingPass
                                                            #ifdef SCENEPICKINGPASS
                                                            float4 _SelectionID;
                                                            #endif

                                                            // -- Properties used by SceneSelectionPass
                                                            #ifdef SCENESELECTIONPASS
                                                            int _ObjectId;
                                                            int _PassValue;
                                                            #endif

                                                            // Graph Functions

                                                            void Unity_Subtract_float2(float2 A, float2 B, out float2 Out)
                                                            {
                                                                Out = A - B;
                                                            }

                                                            void Unity_Normalize_float2(float2 In, out float2 Out)
                                                            {
                                                                Out = normalize(In);
                                                            }

                                                            void Unity_Multiply_float_float(float A, float B, out float Out)
                                                            {
                                                                Out = A * B;
                                                            }

                                                            void Unity_DegreesToRadians_float(float In, out float Out)
                                                            {
                                                                Out = radians(In);
                                                            }

                                                            void Unity_Tangent_float(float In, out float Out)
                                                            {
                                                                Out = tan(In);
                                                            }

                                                            void Unity_Distance_float3(float3 A, float3 B, out float Out)
                                                            {
                                                                Out = distance(A, B);
                                                            }

                                                            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
                                                            {
                                                                Out = A / B;
                                                            }

                                                            void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
                                                            {
                                                                Out = A * B;
                                                            }

                                                            void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                                                            {
                                                                Out = A * B;
                                                            }

                                                            void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
                                                            {
                                                                Out = A - B;
                                                            }

                                                            void Unity_Normalize_float3(float3 In, out float3 Out)
                                                            {
                                                                Out = normalize(In);
                                                            }

                                                            void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                                                            {
                                                                Out = dot(A, B);
                                                            }

                                                            void Unity_Saturate_float(float In, out float Out)
                                                            {
                                                                Out = saturate(In);
                                                            }

                                                            void Unity_Arccosine_float(float In, out float Out)
                                                            {
                                                                Out = acos(In);
                                                            }

                                                            void Unity_Divide_float(float A, float B, out float Out)
                                                            {
                                                                Out = A / B;
                                                            }

                                                            void Unity_OneMinus_float(float In, out float Out)
                                                            {
                                                                Out = 1 - In;
                                                            }

                                                            void Unity_Power_float(float A, float B, out float Out)
                                                            {
                                                                Out = pow(A, B);
                                                            }

                                                            void Unity_Clamp_float(float In, float Min, float Max, out float Out)
                                                            {
                                                                Out = clamp(In, Min, Max);
                                                            }

                                                            void Unity_Add_float2(float2 A, float2 B, out float2 Out)
                                                            {
                                                                Out = A + B;
                                                            }

                                                            void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                                                            {
                                                                Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                                                            }

                                                            void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
                                                            {
                                                                Out = A * B;
                                                            }

                                                            void Unity_Add_float4(float4 A, float4 B, out float4 Out)
                                                            {
                                                                Out = A + B;
                                                            }

                                                            void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                                                            {
                                                                Out = lerp(A, B, T);
                                                            }

                                                            // Custom interpolators pre vertex
                                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                            // Graph Vertex
                                                            struct VertexDescription
                                                            {
                                                                float3 Position;
                                                                float3 Normal;
                                                                float3 Tangent;
                                                            };

                                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                            {
                                                                VertexDescription description = (VertexDescription)0;
                                                                description.Position = IN.ObjectSpacePosition;
                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                return description;
                                                            }

                                                            // Custom interpolators, pre surface
                                                            #ifdef FEATURES_GRAPH_VERTEX
                                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                            {
                                                            return output;
                                                            }
                                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                            #endif

                                                            // Graph Pixel
                                                            struct SurfaceDescription
                                                            {
                                                                float3 BaseColor;
                                                                float Alpha;
                                                            };

                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                            {
                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                UnityTexture2D _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0 = UnityBuildTexture2DStructNoScale(_GrabbedTexture);
                                                                float4 _ScreenPosition_51105a22f54e4d17b09afa91db32071a_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                                                                float2 _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPosition_1;
                                                                float2 _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2;
                                                                GetScreenPosition_float(SHADERGRAPH_OBJECT_POSITION, _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPosition_1, _GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2);
                                                                float2 _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPosition_1;
                                                                float2 _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2;
                                                                GetScreenPosition_float(IN.WorldSpacePosition, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPosition_1, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2);
                                                                float2 _Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2;
                                                                Unity_Subtract_float2(_GetScreenPositionCustomFunction_3c1d19fa48c249339aba4bbc33e46400_ScreenPositionAspectRatio_2, _GetScreenPositionCustomFunction_b7743c8412ca450f831611b820715794_ScreenPositionAspectRatio_2, _Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2);
                                                                float2 _Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1;
                                                                Unity_Normalize_float2(_Subtract_e60c96d6194340ad9866d988055ca8cb_Out_2, _Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1);
                                                                float _Float_0858218bbadb4cc28f688cb222045023_Out_0 = 60;
                                                                float _Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2;
                                                                Unity_Multiply_float_float(_Float_0858218bbadb4cc28f688cb222045023_Out_0, 0.5, _Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2);
                                                                float _DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1;
                                                                Unity_DegreesToRadians_float(_Multiply_16dd2fe4344c4eedb82ed6dd7a432799_Out_2, _DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1);
                                                                float _Tangent_d697099132a843598d53fc44f3f54c90_Out_1;
                                                                Unity_Tangent_float(_DegreesToRadians_18191b7921c94a9b90755f45e637d47e_Out_1, _Tangent_d697099132a843598d53fc44f3f54c90_Out_1);
                                                                float _Float_ee7eb256b7d54ae091cd271ab04c6477_Out_0 = 2;
                                                                float _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2;
                                                                Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, _WorldSpaceCameraPos, _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2);
                                                                float _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2;
                                                                Unity_Multiply_float_float(_Float_ee7eb256b7d54ae091cd271ab04c6477_Out_0, _Distance_0a21289d4c984b5f9e206a13c0581f70_Out_2, _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2);
                                                                float _Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2;
                                                                Unity_Multiply_float_float(_Tangent_d697099132a843598d53fc44f3f54c90_Out_1, _Multiply_77af4313ebdc4b86828b636575fcd35f_Out_2, _Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2);
                                                                float3 _Divide_83f1d10c3d7546548385d5647435e568_Out_2;
                                                                Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                                                                         length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                                                                         length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), (_Multiply_28bb151b7ef74bcda6d782f8fcd32311_Out_2.xxx), _Divide_83f1d10c3d7546548385d5647435e568_Out_2);
                                                                float _Property_6cae10d9522b436cb4146d7228c68a7a_Out_0 = _ScreenSpaceScale;
                                                                float3 _Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2;
                                                                Unity_Multiply_float3_float3(_Divide_83f1d10c3d7546548385d5647435e568_Out_2, (_Property_6cae10d9522b436cb4146d7228c68a7a_Out_0.xxx), _Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2);
                                                                float2 _Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2;
                                                                Unity_Multiply_float2_float2(_Normalize_1b9c05f655b94453ba1073d52bef9709_Out_1, (_Multiply_d2c3bd5655bf4ef69e16cdf800a44648_Out_2.xy), _Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2);
                                                                float3 _Subtract_7f0599c639db43d48cc59ff866e01213_Out_2;
                                                                Unity_Subtract_float3(_WorldSpaceCameraPos, SHADERGRAPH_OBJECT_POSITION, _Subtract_7f0599c639db43d48cc59ff866e01213_Out_2);
                                                                float3 _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1;
                                                                Unity_Normalize_float3(_Subtract_7f0599c639db43d48cc59ff866e01213_Out_2, _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1);
                                                                float _DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2;
                                                                Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_fbc6dd0b07024529861e7b1735fdaf35_Out_1, _DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2);
                                                                float _Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1;
                                                                Unity_Saturate_float(_DotProduct_3c6a20de9b50422dbf067742980201d3_Out_2, _Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1);
                                                                float _Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1;
                                                                Unity_Arccosine_float(_Saturate_403539f79d6a42cda86adb9741fd52fe_Out_1, _Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1);
                                                                float _Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2;
                                                                Unity_Divide_float(_Arccosine_f3025c006ad3472cbfe6e60d637696b4_Out_1, 1.57075, _Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2);
                                                                float _OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1;
                                                                Unity_OneMinus_float(_Divide_7cc46f871ead490c9bf233b811cf83c3_Out_2, _OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1);
                                                                float _Property_0ab81713536143a48e05ed2ef1bdd6ca_Out_0 = _SpherePercentage;
                                                                float _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1;
                                                                Unity_OneMinus_float(_Property_0ab81713536143a48e05ed2ef1bdd6ca_Out_0, _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1);
                                                                float _Divide_aab7449732a344818563e747c68a86fd_Out_2;
                                                                Unity_Divide_float(_OneMinus_289e9fc52a224cb6af0a106e99512c29_Out_1, _OneMinus_1e7cb739149a4faf90986662831f883c_Out_1, _Divide_aab7449732a344818563e747c68a86fd_Out_2);
                                                                float _Property_36f3e10155e04a81a5bda9271d7a77d2_Out_0 = Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                float _Power_2d1c93be45114f68bdc1accd169c9d66_Out_2;
                                                                Unity_Power_float(_Divide_aab7449732a344818563e747c68a86fd_Out_2, _Property_36f3e10155e04a81a5bda9271d7a77d2_Out_0, _Power_2d1c93be45114f68bdc1accd169c9d66_Out_2);
                                                                float3 _Multiply_7848de06422741ff96e8906ad1c95f21_Out_2;
                                                                Unity_Multiply_float3_float3(IN.WorldSpaceViewDirection, float3(-1, -1, -1), _Multiply_7848de06422741ff96e8906ad1c95f21_Out_2);
                                                                float3 _Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2;
                                                                Unity_Subtract_float3(SHADERGRAPH_OBJECT_POSITION, _WorldSpaceCameraPos, _Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2);
                                                                float3 _Normalize_166734be3f694661b28e2eced2e7107a_Out_1;
                                                                Unity_Normalize_float3(_Subtract_606b008a0a2f407da7a4d1b40dfeee1e_Out_2, _Normalize_166734be3f694661b28e2eced2e7107a_Out_1);
                                                                float _DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2;
                                                                Unity_DotProduct_float3(_Multiply_7848de06422741ff96e8906ad1c95f21_Out_2, _Normalize_166734be3f694661b28e2eced2e7107a_Out_1, _DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2);
                                                                float _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3;
                                                                Unity_Clamp_float(_DotProduct_1580f1b77932423ea2375e6a127efbb4_Out_2, 0, 1, _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3);
                                                                float _Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2;
                                                                Unity_Multiply_float_float(_Power_2d1c93be45114f68bdc1accd169c9d66_Out_2, _Clamp_344eaf095fe84cb7bbda01175775d0fc_Out_3, _Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2);
                                                                float2 _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2;
                                                                Unity_Multiply_float2_float2(_Multiply_e5f260498b084e729843eb75bdc6a72e_Out_2, (_Multiply_5cd8f065d177420aa8e0967fd5ad50c3_Out_2.xx), _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2);
                                                                float2 _Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2;
                                                                Unity_Add_float2((_ScreenPosition_51105a22f54e4d17b09afa91db32071a_Out_0.xy), _Multiply_a985df3706c149169f8239e2cb184ca7_Out_2, _Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2);
                                                                float2 _MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1;
                                                                MirrorUVCoordinates_float(_Add_a9e4173511134d6bb3f0a02c26d128ac_Out_2, _MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1);
                                                                float4 _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.tex, _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.samplerstate, _Property_4e965531e2ed40e9959d9b6bb09e2b91_Out_0.GetTransformedUV(_MirrorUVCoordinatesCustomFunction_172327517d8f48feaecd185f43b193b8_NewUVs_1));
                                                                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_R_4 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.r;
                                                                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_G_5 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.g;
                                                                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_B_6 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.b;
                                                                float _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_A_7 = _SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0.a;
                                                                float3 _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1;
                                                                Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1);
                                                                float _Property_4c613d3b075447e1a3665e411e69b0c0_Out_0 = _SpherePercentage;
                                                                float3 _Multiply_51944a57b67f4483b3d1cb938905510b_Out_2;
                                                                Unity_Multiply_float3_float3((_Property_4c613d3b075447e1a3665e411e69b0c0_Out_0.xxx), float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                                                                         length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                                                                         length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_51944a57b67f4483b3d1cb938905510b_Out_2);
                                                                float _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4;
                                                                float3 _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitPosition_5;
                                                                float3 _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6;
                                                                Raycast_float(_WorldSpaceCameraPos, _Normalize_aa0365180d704b8ba4e9302c72f33bd1_Out_1, SHADERGRAPH_OBJECT_POSITION, (_Multiply_51944a57b67f4483b3d1cb938905510b_Out_2).x, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitPosition_5, _RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6);
                                                                float _OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1;
                                                                Unity_OneMinus_float(_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4, _OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1);
                                                                float4 _Property_85c759db8b2244fea01e7b592f2c2543_Out_0 = Color_f649559c5a534a89a4820a4d0c46d676;
                                                                float _Property_d12b7c94c2834ff89b28eec2f4d5ee63_Out_0 = Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                float _FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3;
                                                                Unity_FresnelEffect_float(_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_HitNormal_6, IN.WorldSpaceViewDirection, _Property_d12b7c94c2834ff89b28eec2f4d5ee63_Out_0, _FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3);
                                                                float _Property_fde8720b3dd647c7b469ace795991409_Out_0 = Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                float _Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2;
                                                                Unity_Multiply_float_float(_FresnelEffect_9e23b6e9077b4d8ead6297aeea82fe73_Out_3, _Property_fde8720b3dd647c7b469ace795991409_Out_0, _Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2);
                                                                float4 _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2;
                                                                Unity_Multiply_float4_float4(_Property_85c759db8b2244fea01e7b592f2c2543_Out_0, (_Multiply_508126c107c74cc39a87c4ca0aee5af9_Out_2.xxxx), _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2);
                                                                float4 _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2;
                                                                Unity_Add_float4((_OneMinus_61c365b6e950459aa7264e7d1d5f8e54_Out_1.xxxx), _Multiply_40874f7ce7a64b41aff0660028aaed85_Out_2, _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2);
                                                                float4 _Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3;
                                                                Unity_Lerp_float4(_SampleTexture2D_c7cc7e20716a422a8750e38c7926f0f2_RGBA_0, _Add_2d0383cc6371444f890dd857b7a92cf9_Out_2, (_RaycastCustomFunction_23e915f2cf86468380a8fa3f71c14bde_Hit_4.xxxx), _Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3);
                                                                surface.BaseColor = (_Lerp_53c2dfa4d7fe40d1ba03409ffcf46293_Out_3.xyz);
                                                                surface.Alpha = 1;
                                                                return surface;
                                                            }

                                                            // --------------------------------------------------
                                                            // Build Graph Inputs
                                                            #ifdef HAVE_VFX_MODIFICATION
                                                            #define VFX_SRP_ATTRIBUTES Attributes
                                                            #define VFX_SRP_VARYINGS Varyings
                                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                            #endif
                                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                            {
                                                                VertexDescriptionInputs output;
                                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                output.ObjectSpaceNormal = input.normalOS;
                                                                output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                output.ObjectSpacePosition = input.positionOS;

                                                                return output;
                                                            }
                                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                            {
                                                                SurfaceDescriptionInputs output;
                                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                            #endif



                                                                // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                                                                float3 unnormalizedNormalWS = input.normalWS;
                                                                const float renormFactor = 1.0 / length(unnormalizedNormalWS);


                                                                output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph


                                                                output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
                                                                output.WorldSpacePosition = input.positionWS;
                                                                output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                            #else
                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                            #endif
                                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                    return output;
                                                            }

                                                            // --------------------------------------------------
                                                            // Main

                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"

                                                            // --------------------------------------------------
                                                            // Visual Effect Vertex Invocations
                                                            #ifdef HAVE_VFX_MODIFICATION
                                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                            #endif

                                                            ENDHLSL
                                                            }
                                                            Pass
                                                            {
                                                                Name "DepthNormalsOnly"
                                                                Tags
                                                                {
                                                                    "LightMode" = "DepthNormalsOnly"
                                                                }

                                                                // Render State
                                                                Cull Back
                                                                ZTest LEqual
                                                                ZWrite On

                                                                // Debug
                                                                // <None>

                                                                // --------------------------------------------------
                                                                // Pass

                                                                HLSLPROGRAM

                                                                // Pragmas
                                                                #pragma target 2.0
                                                                #pragma only_renderers gles gles3 glcore d3d11
                                                                #pragma multi_compile_instancing
                                                                #pragma vertex vert
                                                                #pragma fragment frag

                                                                // DotsInstancingOptions: <None>
                                                                // HybridV1InjectedBuiltinProperties: <None>

                                                                // Keywords
                                                                // PassKeywords: <None>
                                                                // GraphKeywords: <None>

                                                                // Defines

                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                #define ATTRIBUTES_NEED_TEXCOORD1
                                                                #define VARYINGS_NEED_NORMAL_WS
                                                                #define VARYINGS_NEED_TANGENT_WS
                                                                #define FEATURES_GRAPH_VERTEX
                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                // custom interpolator pre-include
                                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                // Includes
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                // --------------------------------------------------
                                                                // Structs and Packing

                                                                // custom interpolators pre packing
                                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                struct Attributes
                                                                {
                                                                     float3 positionOS : POSITION;
                                                                     float3 normalOS : NORMAL;
                                                                     float4 tangentOS : TANGENT;
                                                                     float4 uv1 : TEXCOORD1;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                                    #endif
                                                                };
                                                                struct Varyings
                                                                {
                                                                     float4 positionCS : SV_POSITION;
                                                                     float3 normalWS;
                                                                     float4 tangentWS;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                    #endif
                                                                };
                                                                struct SurfaceDescriptionInputs
                                                                {
                                                                };
                                                                struct VertexDescriptionInputs
                                                                {
                                                                     float3 ObjectSpaceNormal;
                                                                     float3 ObjectSpaceTangent;
                                                                     float3 ObjectSpacePosition;
                                                                };
                                                                struct PackedVaryings
                                                                {
                                                                     float4 positionCS : SV_POSITION;
                                                                     float4 tangentWS : INTERP0;
                                                                     float3 normalWS : INTERP1;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                    #endif
                                                                };

                                                                PackedVaryings PackVaryings(Varyings input)
                                                                {
                                                                    PackedVaryings output;
                                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                                    output.positionCS = input.positionCS;
                                                                    output.tangentWS.xyzw = input.tangentWS;
                                                                    output.normalWS.xyz = input.normalWS;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    output.instanceID = input.instanceID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    output.cullFace = input.cullFace;
                                                                    #endif
                                                                    return output;
                                                                }

                                                                Varyings UnpackVaryings(PackedVaryings input)
                                                                {
                                                                    Varyings output;
                                                                    output.positionCS = input.positionCS;
                                                                    output.tangentWS = input.tangentWS.xyzw;
                                                                    output.normalWS = input.normalWS.xyz;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    output.instanceID = input.instanceID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    output.cullFace = input.cullFace;
                                                                    #endif
                                                                    return output;
                                                                }


                                                                // --------------------------------------------------
                                                                // Graph

                                                                // Graph Properties
                                                                CBUFFER_START(UnityPerMaterial)
                                                                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                                float _ScreenSpaceScale;
                                                                float _SpherePercentage;
                                                                CBUFFER_END

                                                                    // Object and Global properties
                                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                                    TEXTURE2D(_GrabbedTexture);
                                                                    SAMPLER(sampler_GrabbedTexture);
                                                                    float4 _GrabbedTexture_TexelSize;

                                                                    // Graph Includes
                                                                    // GraphIncludes: <None>

                                                                    // -- Property used by ScenePickingPass
                                                                    #ifdef SCENEPICKINGPASS
                                                                    float4 _SelectionID;
                                                                    #endif

                                                                    // -- Properties used by SceneSelectionPass
                                                                    #ifdef SCENESELECTIONPASS
                                                                    int _ObjectId;
                                                                    int _PassValue;
                                                                    #endif

                                                                    // Graph Functions
                                                                    // GraphFunctions: <None>

                                                                    // Custom interpolators pre vertex
                                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                    // Graph Vertex
                                                                    struct VertexDescription
                                                                    {
                                                                        float3 Position;
                                                                        float3 Normal;
                                                                        float3 Tangent;
                                                                    };

                                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                    {
                                                                        VertexDescription description = (VertexDescription)0;
                                                                        description.Position = IN.ObjectSpacePosition;
                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                        return description;
                                                                    }

                                                                    // Custom interpolators, pre surface
                                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                    {
                                                                    return output;
                                                                    }
                                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                    #endif

                                                                    // Graph Pixel
                                                                    struct SurfaceDescription
                                                                    {
                                                                        float Alpha;
                                                                    };

                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                    {
                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                        surface.Alpha = 1;
                                                                        return surface;
                                                                    }

                                                                    // --------------------------------------------------
                                                                    // Build Graph Inputs
                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                                    #define VFX_SRP_VARYINGS Varyings
                                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                    #endif
                                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                    {
                                                                        VertexDescriptionInputs output;
                                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                        output.ObjectSpaceNormal = input.normalOS;
                                                                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                        output.ObjectSpacePosition = input.positionOS;

                                                                        return output;
                                                                    }
                                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                    {
                                                                        SurfaceDescriptionInputs output;
                                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                    #endif







                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                    #else
                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                    #endif
                                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                            return output;
                                                                    }

                                                                    // --------------------------------------------------
                                                                    // Main

                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                                                                    // --------------------------------------------------
                                                                    // Visual Effect Vertex Invocations
                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                    #endif

                                                                    ENDHLSL
                                                                    }
                                                                    Pass
                                                                    {
                                                                        Name "ShadowCaster"
                                                                        Tags
                                                                        {
                                                                            "LightMode" = "ShadowCaster"
                                                                        }

                                                                        // Render State
                                                                        Cull Back
                                                                        ZTest LEqual
                                                                        ZWrite On
                                                                        ColorMask 0

                                                                        // Debug
                                                                        // <None>

                                                                        // --------------------------------------------------
                                                                        // Pass

                                                                        HLSLPROGRAM

                                                                        // Pragmas
                                                                        #pragma target 2.0
                                                                        #pragma only_renderers gles gles3 glcore d3d11
                                                                        #pragma multi_compile_instancing
                                                                        #pragma vertex vert
                                                                        #pragma fragment frag

                                                                        // DotsInstancingOptions: <None>
                                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                                        // Keywords
                                                                        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
                                                                        // GraphKeywords: <None>

                                                                        // Defines

                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                        #define VARYINGS_NEED_NORMAL_WS
                                                                        #define FEATURES_GRAPH_VERTEX
                                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                        #define SHADERPASS SHADERPASS_SHADOWCASTER
                                                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                        // custom interpolator pre-include
                                                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                        // Includes
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                        // --------------------------------------------------
                                                                        // Structs and Packing

                                                                        // custom interpolators pre packing
                                                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                        struct Attributes
                                                                        {
                                                                             float3 positionOS : POSITION;
                                                                             float3 normalOS : NORMAL;
                                                                             float4 tangentOS : TANGENT;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                             uint instanceID : INSTANCEID_SEMANTIC;
                                                                            #endif
                                                                        };
                                                                        struct Varyings
                                                                        {
                                                                             float4 positionCS : SV_POSITION;
                                                                             float3 normalWS;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                            #endif
                                                                        };
                                                                        struct SurfaceDescriptionInputs
                                                                        {
                                                                        };
                                                                        struct VertexDescriptionInputs
                                                                        {
                                                                             float3 ObjectSpaceNormal;
                                                                             float3 ObjectSpaceTangent;
                                                                             float3 ObjectSpacePosition;
                                                                        };
                                                                        struct PackedVaryings
                                                                        {
                                                                             float4 positionCS : SV_POSITION;
                                                                             float3 normalWS : INTERP0;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                            #endif
                                                                        };

                                                                        PackedVaryings PackVaryings(Varyings input)
                                                                        {
                                                                            PackedVaryings output;
                                                                            ZERO_INITIALIZE(PackedVaryings, output);
                                                                            output.positionCS = input.positionCS;
                                                                            output.normalWS.xyz = input.normalWS;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            output.instanceID = input.instanceID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            output.cullFace = input.cullFace;
                                                                            #endif
                                                                            return output;
                                                                        }

                                                                        Varyings UnpackVaryings(PackedVaryings input)
                                                                        {
                                                                            Varyings output;
                                                                            output.positionCS = input.positionCS;
                                                                            output.normalWS = input.normalWS.xyz;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            output.instanceID = input.instanceID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            output.cullFace = input.cullFace;
                                                                            #endif
                                                                            return output;
                                                                        }


                                                                        // --------------------------------------------------
                                                                        // Graph

                                                                        // Graph Properties
                                                                        CBUFFER_START(UnityPerMaterial)
                                                                        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                        float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                        float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                        float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                                        float _ScreenSpaceScale;
                                                                        float _SpherePercentage;
                                                                        CBUFFER_END

                                                                            // Object and Global properties
                                                                            SAMPLER(SamplerState_Linear_Repeat);
                                                                            TEXTURE2D(_GrabbedTexture);
                                                                            SAMPLER(sampler_GrabbedTexture);
                                                                            float4 _GrabbedTexture_TexelSize;

                                                                            // Graph Includes
                                                                            // GraphIncludes: <None>

                                                                            // -- Property used by ScenePickingPass
                                                                            #ifdef SCENEPICKINGPASS
                                                                            float4 _SelectionID;
                                                                            #endif

                                                                            // -- Properties used by SceneSelectionPass
                                                                            #ifdef SCENESELECTIONPASS
                                                                            int _ObjectId;
                                                                            int _PassValue;
                                                                            #endif

                                                                            // Graph Functions
                                                                            // GraphFunctions: <None>

                                                                            // Custom interpolators pre vertex
                                                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                            // Graph Vertex
                                                                            struct VertexDescription
                                                                            {
                                                                                float3 Position;
                                                                                float3 Normal;
                                                                                float3 Tangent;
                                                                            };

                                                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                            {
                                                                                VertexDescription description = (VertexDescription)0;
                                                                                description.Position = IN.ObjectSpacePosition;
                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                return description;
                                                                            }

                                                                            // Custom interpolators, pre surface
                                                                            #ifdef FEATURES_GRAPH_VERTEX
                                                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                            {
                                                                            return output;
                                                                            }
                                                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                            #endif

                                                                            // Graph Pixel
                                                                            struct SurfaceDescription
                                                                            {
                                                                                float Alpha;
                                                                            };

                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                            {
                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                surface.Alpha = 1;
                                                                                return surface;
                                                                            }

                                                                            // --------------------------------------------------
                                                                            // Build Graph Inputs
                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                            #define VFX_SRP_ATTRIBUTES Attributes
                                                                            #define VFX_SRP_VARYINGS Varyings
                                                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                            #endif
                                                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                            {
                                                                                VertexDescriptionInputs output;
                                                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                                output.ObjectSpaceNormal = input.normalOS;
                                                                                output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                                output.ObjectSpacePosition = input.positionOS;

                                                                                return output;
                                                                            }
                                                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                            {
                                                                                SurfaceDescriptionInputs output;
                                                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                            #endif







                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                            #else
                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                            #endif
                                                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                                    return output;
                                                                            }

                                                                            // --------------------------------------------------
                                                                            // Main

                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

                                                                            // --------------------------------------------------
                                                                            // Visual Effect Vertex Invocations
                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                            #endif

                                                                            ENDHLSL
                                                                            }
                                                                            Pass
                                                                            {
                                                                                Name "SceneSelectionPass"
                                                                                Tags
                                                                                {
                                                                                    "LightMode" = "SceneSelectionPass"
                                                                                }

                                                                                // Render State
                                                                                Cull Off

                                                                                // Debug
                                                                                // <None>

                                                                                // --------------------------------------------------
                                                                                // Pass

                                                                                HLSLPROGRAM

                                                                                // Pragmas
                                                                                #pragma target 2.0
                                                                                #pragma only_renderers gles gles3 glcore d3d11
                                                                                #pragma multi_compile_instancing
                                                                                #pragma vertex vert
                                                                                #pragma fragment frag

                                                                                // DotsInstancingOptions: <None>
                                                                                // HybridV1InjectedBuiltinProperties: <None>

                                                                                // Keywords
                                                                                // PassKeywords: <None>
                                                                                // GraphKeywords: <None>

                                                                                // Defines

                                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                                #define FEATURES_GRAPH_VERTEX
                                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                #define SHADERPASS SHADERPASS_DEPTHONLY
                                                                                #define SCENESELECTIONPASS 1
                                                                                #define ALPHA_CLIP_THRESHOLD 1
                                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                                // custom interpolator pre-include
                                                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                                // Includes
                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                                // --------------------------------------------------
                                                                                // Structs and Packing

                                                                                // custom interpolators pre packing
                                                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                                struct Attributes
                                                                                {
                                                                                     float3 positionOS : POSITION;
                                                                                     float3 normalOS : NORMAL;
                                                                                     float4 tangentOS : TANGENT;
                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                                                    #endif
                                                                                };
                                                                                struct Varyings
                                                                                {
                                                                                     float4 positionCS : SV_POSITION;
                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                    #endif
                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                    #endif
                                                                                };
                                                                                struct SurfaceDescriptionInputs
                                                                                {
                                                                                };
                                                                                struct VertexDescriptionInputs
                                                                                {
                                                                                     float3 ObjectSpaceNormal;
                                                                                     float3 ObjectSpaceTangent;
                                                                                     float3 ObjectSpacePosition;
                                                                                };
                                                                                struct PackedVaryings
                                                                                {
                                                                                     float4 positionCS : SV_POSITION;
                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                    #endif
                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                    #endif
                                                                                };

                                                                                PackedVaryings PackVaryings(Varyings input)
                                                                                {
                                                                                    PackedVaryings output;
                                                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                                                    output.positionCS = input.positionCS;
                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                    output.instanceID = input.instanceID;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                    #endif
                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                    output.cullFace = input.cullFace;
                                                                                    #endif
                                                                                    return output;
                                                                                }

                                                                                Varyings UnpackVaryings(PackedVaryings input)
                                                                                {
                                                                                    Varyings output;
                                                                                    output.positionCS = input.positionCS;
                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                    output.instanceID = input.instanceID;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                    #endif
                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                    #endif
                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                    output.cullFace = input.cullFace;
                                                                                    #endif
                                                                                    return output;
                                                                                }


                                                                                // --------------------------------------------------
                                                                                // Graph

                                                                                // Graph Properties
                                                                                CBUFFER_START(UnityPerMaterial)
                                                                                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                                                float _ScreenSpaceScale;
                                                                                float _SpherePercentage;
                                                                                CBUFFER_END

                                                                                    // Object and Global properties
                                                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                                                    TEXTURE2D(_GrabbedTexture);
                                                                                    SAMPLER(sampler_GrabbedTexture);
                                                                                    float4 _GrabbedTexture_TexelSize;

                                                                                    // Graph Includes
                                                                                    // GraphIncludes: <None>

                                                                                    // -- Property used by ScenePickingPass
                                                                                    #ifdef SCENEPICKINGPASS
                                                                                    float4 _SelectionID;
                                                                                    #endif

                                                                                    // -- Properties used by SceneSelectionPass
                                                                                    #ifdef SCENESELECTIONPASS
                                                                                    int _ObjectId;
                                                                                    int _PassValue;
                                                                                    #endif

                                                                                    // Graph Functions
                                                                                    // GraphFunctions: <None>

                                                                                    // Custom interpolators pre vertex
                                                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                                    // Graph Vertex
                                                                                    struct VertexDescription
                                                                                    {
                                                                                        float3 Position;
                                                                                        float3 Normal;
                                                                                        float3 Tangent;
                                                                                    };

                                                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                                    {
                                                                                        VertexDescription description = (VertexDescription)0;
                                                                                        description.Position = IN.ObjectSpacePosition;
                                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                                        return description;
                                                                                    }

                                                                                    // Custom interpolators, pre surface
                                                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                                    {
                                                                                    return output;
                                                                                    }
                                                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                                    #endif

                                                                                    // Graph Pixel
                                                                                    struct SurfaceDescription
                                                                                    {
                                                                                        float Alpha;
                                                                                    };

                                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                    {
                                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                                        surface.Alpha = 1;
                                                                                        return surface;
                                                                                    }

                                                                                    // --------------------------------------------------
                                                                                    // Build Graph Inputs
                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                                                    #define VFX_SRP_VARYINGS Varyings
                                                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                                    #endif
                                                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                                    {
                                                                                        VertexDescriptionInputs output;
                                                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                                        output.ObjectSpaceNormal = input.normalOS;
                                                                                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                                        output.ObjectSpacePosition = input.positionOS;

                                                                                        return output;
                                                                                    }
                                                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                                    {
                                                                                        SurfaceDescriptionInputs output;
                                                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                                    #endif







                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                                    #else
                                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                                    #endif
                                                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                                            return output;
                                                                                    }

                                                                                    // --------------------------------------------------
                                                                                    // Main

                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                                                                    // --------------------------------------------------
                                                                                    // Visual Effect Vertex Invocations
                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                                    #endif

                                                                                    ENDHLSL
                                                                                    }
                                                                                    Pass
                                                                                    {
                                                                                        Name "ScenePickingPass"
                                                                                        Tags
                                                                                        {
                                                                                            "LightMode" = "Picking"
                                                                                        }

                                                                                        // Render State
                                                                                        Cull Back

                                                                                        // Debug
                                                                                        // <None>

                                                                                        // --------------------------------------------------
                                                                                        // Pass

                                                                                        HLSLPROGRAM

                                                                                        // Pragmas
                                                                                        #pragma target 2.0
                                                                                        #pragma only_renderers gles gles3 glcore d3d11
                                                                                        #pragma multi_compile_instancing
                                                                                        #pragma vertex vert
                                                                                        #pragma fragment frag

                                                                                        // DotsInstancingOptions: <None>
                                                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                                                        // Keywords
                                                                                        // PassKeywords: <None>
                                                                                        // GraphKeywords: <None>

                                                                                        // Defines

                                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                                        #define FEATURES_GRAPH_VERTEX
                                                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                        #define SHADERPASS SHADERPASS_DEPTHONLY
                                                                                        #define SCENEPICKINGPASS 1
                                                                                        #define ALPHA_CLIP_THRESHOLD 1
                                                                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                                        // custom interpolator pre-include
                                                                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                                        // Includes
                                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                                        // --------------------------------------------------
                                                                                        // Structs and Packing

                                                                                        // custom interpolators pre packing
                                                                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                                        struct Attributes
                                                                                        {
                                                                                             float3 positionOS : POSITION;
                                                                                             float3 normalOS : NORMAL;
                                                                                             float4 tangentOS : TANGENT;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                             uint instanceID : INSTANCEID_SEMANTIC;
                                                                                            #endif
                                                                                        };
                                                                                        struct Varyings
                                                                                        {
                                                                                             float4 positionCS : SV_POSITION;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                            #endif
                                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                            #endif
                                                                                        };
                                                                                        struct SurfaceDescriptionInputs
                                                                                        {
                                                                                        };
                                                                                        struct VertexDescriptionInputs
                                                                                        {
                                                                                             float3 ObjectSpaceNormal;
                                                                                             float3 ObjectSpaceTangent;
                                                                                             float3 ObjectSpacePosition;
                                                                                        };
                                                                                        struct PackedVaryings
                                                                                        {
                                                                                             float4 positionCS : SV_POSITION;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                            #endif
                                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                            #endif
                                                                                        };

                                                                                        PackedVaryings PackVaryings(Varyings input)
                                                                                        {
                                                                                            PackedVaryings output;
                                                                                            ZERO_INITIALIZE(PackedVaryings, output);
                                                                                            output.positionCS = input.positionCS;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                            output.instanceID = input.instanceID;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                            #endif
                                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                            output.cullFace = input.cullFace;
                                                                                            #endif
                                                                                            return output;
                                                                                        }

                                                                                        Varyings UnpackVaryings(PackedVaryings input)
                                                                                        {
                                                                                            Varyings output;
                                                                                            output.positionCS = input.positionCS;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                            output.instanceID = input.instanceID;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                            #endif
                                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                            #endif
                                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                            output.cullFace = input.cullFace;
                                                                                            #endif
                                                                                            return output;
                                                                                        }


                                                                                        // --------------------------------------------------
                                                                                        // Graph

                                                                                        // Graph Properties
                                                                                        CBUFFER_START(UnityPerMaterial)
                                                                                        float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                                        float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                                        float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                                        float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                                                        float _ScreenSpaceScale;
                                                                                        float _SpherePercentage;
                                                                                        CBUFFER_END

                                                                                            // Object and Global properties
                                                                                            SAMPLER(SamplerState_Linear_Repeat);
                                                                                            TEXTURE2D(_GrabbedTexture);
                                                                                            SAMPLER(sampler_GrabbedTexture);
                                                                                            float4 _GrabbedTexture_TexelSize;

                                                                                            // Graph Includes
                                                                                            // GraphIncludes: <None>

                                                                                            // -- Property used by ScenePickingPass
                                                                                            #ifdef SCENEPICKINGPASS
                                                                                            float4 _SelectionID;
                                                                                            #endif

                                                                                            // -- Properties used by SceneSelectionPass
                                                                                            #ifdef SCENESELECTIONPASS
                                                                                            int _ObjectId;
                                                                                            int _PassValue;
                                                                                            #endif

                                                                                            // Graph Functions
                                                                                            // GraphFunctions: <None>

                                                                                            // Custom interpolators pre vertex
                                                                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                                            // Graph Vertex
                                                                                            struct VertexDescription
                                                                                            {
                                                                                                float3 Position;
                                                                                                float3 Normal;
                                                                                                float3 Tangent;
                                                                                            };

                                                                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                                            {
                                                                                                VertexDescription description = (VertexDescription)0;
                                                                                                description.Position = IN.ObjectSpacePosition;
                                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                                return description;
                                                                                            }

                                                                                            // Custom interpolators, pre surface
                                                                                            #ifdef FEATURES_GRAPH_VERTEX
                                                                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                                            {
                                                                                            return output;
                                                                                            }
                                                                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                                            #endif

                                                                                            // Graph Pixel
                                                                                            struct SurfaceDescription
                                                                                            {
                                                                                                float Alpha;
                                                                                            };

                                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                            {
                                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                                surface.Alpha = 1;
                                                                                                return surface;
                                                                                            }

                                                                                            // --------------------------------------------------
                                                                                            // Build Graph Inputs
                                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                                            #define VFX_SRP_ATTRIBUTES Attributes
                                                                                            #define VFX_SRP_VARYINGS Varyings
                                                                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                                            #endif
                                                                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                                            {
                                                                                                VertexDescriptionInputs output;
                                                                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                                                output.ObjectSpaceNormal = input.normalOS;
                                                                                                output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                                                output.ObjectSpacePosition = input.positionOS;

                                                                                                return output;
                                                                                            }
                                                                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                                            {
                                                                                                SurfaceDescriptionInputs output;
                                                                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                                            #endif







                                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                                            #else
                                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                                            #endif
                                                                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                                                    return output;
                                                                                            }

                                                                                            // --------------------------------------------------
                                                                                            // Main

                                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                                                                            // --------------------------------------------------
                                                                                            // Visual Effect Vertex Invocations
                                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                                            #endif

                                                                                            ENDHLSL
                                                                                            }
                                                                                            Pass
                                                                                            {
                                                                                                Name "DepthNormals"
                                                                                                Tags
                                                                                                {
                                                                                                    "LightMode" = "DepthNormalsOnly"
                                                                                                }

                                                                                                // Render State
                                                                                                Cull Back
                                                                                                ZTest LEqual
                                                                                                ZWrite On

                                                                                                // Debug
                                                                                                // <None>

                                                                                                // --------------------------------------------------
                                                                                                // Pass

                                                                                                HLSLPROGRAM

                                                                                                // Pragmas
                                                                                                #pragma target 2.0
                                                                                                #pragma only_renderers gles gles3 glcore d3d11
                                                                                                #pragma multi_compile_instancing
                                                                                                #pragma multi_compile_fog
                                                                                                #pragma instancing_options renderinglayer
                                                                                                #pragma vertex vert
                                                                                                #pragma fragment frag

                                                                                                // DotsInstancingOptions: <None>
                                                                                                // HybridV1InjectedBuiltinProperties: <None>

                                                                                                // Keywords
                                                                                                // PassKeywords: <None>
                                                                                                // GraphKeywords: <None>

                                                                                                // Defines

                                                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                                                #define VARYINGS_NEED_NORMAL_WS
                                                                                                #define FEATURES_GRAPH_VERTEX
                                                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                                                                                                #define _SURFACE_TYPE_TRANSPARENT 1
                                                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                                                // custom interpolator pre-include
                                                                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                                                // Includes
                                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                                                // --------------------------------------------------
                                                                                                // Structs and Packing

                                                                                                // custom interpolators pre packing
                                                                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                                                struct Attributes
                                                                                                {
                                                                                                     float3 positionOS : POSITION;
                                                                                                     float3 normalOS : NORMAL;
                                                                                                     float4 tangentOS : TANGENT;
                                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                                                                    #endif
                                                                                                };
                                                                                                struct Varyings
                                                                                                {
                                                                                                     float4 positionCS : SV_POSITION;
                                                                                                     float3 normalWS;
                                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                                    #endif
                                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                                    #endif
                                                                                                };
                                                                                                struct SurfaceDescriptionInputs
                                                                                                {
                                                                                                };
                                                                                                struct VertexDescriptionInputs
                                                                                                {
                                                                                                     float3 ObjectSpaceNormal;
                                                                                                     float3 ObjectSpaceTangent;
                                                                                                     float3 ObjectSpacePosition;
                                                                                                };
                                                                                                struct PackedVaryings
                                                                                                {
                                                                                                     float4 positionCS : SV_POSITION;
                                                                                                     float3 normalWS : INTERP0;
                                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                                                    #endif
                                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                                                    #endif
                                                                                                };

                                                                                                PackedVaryings PackVaryings(Varyings input)
                                                                                                {
                                                                                                    PackedVaryings output;
                                                                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                                                                    output.positionCS = input.positionCS;
                                                                                                    output.normalWS.xyz = input.normalWS;
                                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                                    output.instanceID = input.instanceID;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                                    #endif
                                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                                    output.cullFace = input.cullFace;
                                                                                                    #endif
                                                                                                    return output;
                                                                                                }

                                                                                                Varyings UnpackVaryings(PackedVaryings input)
                                                                                                {
                                                                                                    Varyings output;
                                                                                                    output.positionCS = input.positionCS;
                                                                                                    output.normalWS = input.normalWS.xyz;
                                                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                                                    output.instanceID = input.instanceID;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                                                    #endif
                                                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                                                    #endif
                                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                                    output.cullFace = input.cullFace;
                                                                                                    #endif
                                                                                                    return output;
                                                                                                }


                                                                                                // --------------------------------------------------
                                                                                                // Graph

                                                                                                // Graph Properties
                                                                                                CBUFFER_START(UnityPerMaterial)
                                                                                                float Vector1_0bb6c794ceb5476bbe1601bd36eb7262;
                                                                                                float Vector1_e1206881e1244ef4a008548fa38caa6a;
                                                                                                float Vector1_486f1fcc37a949ffb726a117eab0987a;
                                                                                                float4 Color_f649559c5a534a89a4820a4d0c46d676;
                                                                                                float _ScreenSpaceScale;
                                                                                                float _SpherePercentage;
                                                                                                CBUFFER_END

                                                                                                    // Object and Global properties
                                                                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                                                                    TEXTURE2D(_GrabbedTexture);
                                                                                                    SAMPLER(sampler_GrabbedTexture);
                                                                                                    float4 _GrabbedTexture_TexelSize;

                                                                                                    // Graph Includes
                                                                                                    // GraphIncludes: <None>

                                                                                                    // -- Property used by ScenePickingPass
                                                                                                    #ifdef SCENEPICKINGPASS
                                                                                                    float4 _SelectionID;
                                                                                                    #endif

                                                                                                    // -- Properties used by SceneSelectionPass
                                                                                                    #ifdef SCENESELECTIONPASS
                                                                                                    int _ObjectId;
                                                                                                    int _PassValue;
                                                                                                    #endif

                                                                                                    // Graph Functions
                                                                                                    // GraphFunctions: <None>

                                                                                                    // Custom interpolators pre vertex
                                                                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                                                    // Graph Vertex
                                                                                                    struct VertexDescription
                                                                                                    {
                                                                                                        float3 Position;
                                                                                                        float3 Normal;
                                                                                                        float3 Tangent;
                                                                                                    };

                                                                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                                                    {
                                                                                                        VertexDescription description = (VertexDescription)0;
                                                                                                        description.Position = IN.ObjectSpacePosition;
                                                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                                                        return description;
                                                                                                    }

                                                                                                    // Custom interpolators, pre surface
                                                                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                                                    {
                                                                                                    return output;
                                                                                                    }
                                                                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                                                    #endif

                                                                                                    // Graph Pixel
                                                                                                    struct SurfaceDescription
                                                                                                    {
                                                                                                        float Alpha;
                                                                                                    };

                                                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                                    {
                                                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                                                        surface.Alpha = 1;
                                                                                                        return surface;
                                                                                                    }

                                                                                                    // --------------------------------------------------
                                                                                                    // Build Graph Inputs
                                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                                                                    #define VFX_SRP_VARYINGS Varyings
                                                                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                                                    #endif
                                                                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                                                    {
                                                                                                        VertexDescriptionInputs output;
                                                                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                                                        output.ObjectSpaceNormal = input.normalOS;
                                                                                                        output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                                                        output.ObjectSpacePosition = input.positionOS;

                                                                                                        return output;
                                                                                                    }
                                                                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                                                    {
                                                                                                        SurfaceDescriptionInputs output;
                                                                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                                                    #endif







                                                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                                                    #else
                                                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                                                    #endif
                                                                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                                                            return output;
                                                                                                    }

                                                                                                    // --------------------------------------------------
                                                                                                    // Main

                                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                                                                                                    // --------------------------------------------------
                                                                                                    // Visual Effect Vertex Invocations
                                                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                                                    #endif

                                                                                                    ENDHLSL
                                                                                                    }
                                                    }
                                                        CustomEditorForRenderPipeline "UnityEditor.ShaderGraphUnlitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
                                                                                                        CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
                                                                                                        FallBack "Hidden/Shader Graph/FallbackError"
}