// Copyright (c) 2019 Arm Limited. All rights reserved.
Shader "Custom/Water"
{
    Properties
    {
        _DepthFactor("Depth Factor", float) = 1.0
        _WaveSpeed("Wave Speed", float) = 1.0
        _WaveAmp("Wave Amp", float) = 0.2
        _NoiseTex("Noise Texture", 2D) = "white" {}
        _MainTex("Main Texture", 2D) = "white" {}
        _DistortStrength("Distort Strength", float) = 1.0
        _ExtraHeight("Extra Height", float) = 0.0
    }

    SubShader
    {
        Tags
        { 
         "RenderType"="Transparent"
        }
    
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            // Properties
            float  _DepthFactor;
            float  _WaveSpeed;
            float  _WaveAmp;
            float _ExtraHeight;

            
            sampler2D _CameraDepthTexture;
            sampler2D _NoiseTex;
            sampler2D _MainTex;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float4 uv_texture : TEXCOORD0;      // Random UVs to sample noise
                float4 uv2_distortion : TEXCOORD1;  // Smooth UVs for waves
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 uv_texture : TEXCOORD0;      // Random UVs to sample noise
                float4 worldSpace : TEXCOORD3;
                UNITY_FOG_COORDS(4)
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                output.worldSpace = input.vertex;


                // apply wave animation
                float noiseSample = tex2Dlod(_NoiseTex, float4(input.uv2_distortion.xy, 0, 0));
                input.vertex.y += (sin(_Time*_WaveSpeed*noiseSample)*_WaveAmp) + _ExtraHeight;
                // output.pos.x += cos(_Time*_WaveSpeed*noiseSample)*_WaveAmp;

                // convert to world space
                output.pos = UnityObjectToClipPos(input.vertex);

                // texture coordinates
                output.uv_texture = input.uv_texture;

                UNITY_TRANSFER_FOG(output, output.pos);

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                // sample main texture
                float4 albedo = tex2D(_MainTex, input.uv_texture.xy);

                float4 col = albedo;

                UNITY_APPLY_FOG(input.fogCoord, col);
                return col;
            }

            ENDCG
        }
    }
}