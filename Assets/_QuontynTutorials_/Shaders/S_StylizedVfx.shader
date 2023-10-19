Shader "Custom/S_StylizedVfx"
{
    Properties
    {
        _TrailColor("Trail Color", Color) = (1.0, 1.0, 1.0)

        _CycleTime("Trail Cycle Time", float) = 3.0
        _Delay("Delay Between Cycles", float) = 1.0
        _Offset("Time Offset", float) = 0.0

        _Width("Width", float) = 0.3
        _Thickness("Thickness", float) = 1.0
        _AA("Smoothness", float) = 0.05
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            Name "ForwardRendering"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZTest LEqual
            ZWrite Off

            Cull Off

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            
            #include "Assets/_QuontynTutorials_/Shaders/S_StylizedIncludeFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 vertexColor : COLOR;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 vertexColor : TEXCOORD1;
                float2 uv0 : TEXCOORD2;
                float4 lightmapUV : TEXCOORD3;
                float4 fog : TEXCOORD4;
                float offset : TEXCOORD5;
            };

            float3 _TrailColor;

            float _CycleTime;
            float _Delay;
            float _Offset;

            float _Width;
            float _Thickness;
            float _AA;

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                /* Vertex positions in different coordinate spaces */
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                /* UVs */
                output.uv0 = input.uv0;

                /* Fog */
                output.fog = ComputeFogFactor(vertexInput.positionCS.z);

                /* Vertex Color */
                output.vertexColor = input.vertexColor;

                /*
                // For this demo I'm driving a random offset by the objects postion, so the trails don't all animate at the same time.
                // This is obviously not the best way of doing it because it means the object can never move or else the offset changes :)
                // But, it saves me from setting a different parameter on each material instance! (aka lazy)
                */
                float3 wpos = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).xyz;
                output.offset = CustomRandom(float2(dot(wpos, wpos), wpos.x));

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);

                float trail = EvaluateTrail(input.uv0, _CycleTime, _Delay, input.offset * (_CycleTime + _Delay), _Width, _Thickness, _AA);

                finalColor.rgb = _TrailColor;

                finalColor.a = trail;
                finalColor.a *= pow(input.vertexColor.r, 2.0);

                return finalColor;
            }


            ENDHLSL
        }
    }
}
