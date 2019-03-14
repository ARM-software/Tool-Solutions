// Copyright (c) 2019 Arm Limited. All rights reserved.
 Shader "Custom/Ground"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        { 
            "Queue" = "Geometry"
            "LightMode"="ForwardBase"   // Needed as we are calculating lighting
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc" // for _LightColor0
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            sampler2D _MainTex;
            
            struct vertexInput
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 uv_texture : TEXCOORD0;      // Random UVs to sample noise
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                fixed4 diff : COLOR0;               // Diffuse light colour.
                float4 uv_texture : TEXCOORD0;      // Random UVs to sample noise
                float4 worldSpace : TEXCOORD2;
                UNITY_FOG_COORDS(3)
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                output.worldSpace = input.vertex;

                // convert to world space
                output.pos = UnityObjectToClipPos(input.vertex);

                // texture coordinates
                output.uv_texture = input.uv_texture;

                UNITY_TRANSFER_FOG(output, output.pos);

                // get vertex normal in world space
                half3 worldNormal = UnityObjectToWorldNormal(input.normal);
                // dot product between normal and light direction for
                // standard diffuse (Lambert) lighting
                half3 vertical = half3(1.0, 0.0, 0.0 );
                half nl = max(0, dot(worldNormal, vertical));
                nl = 0.5 + nl/1.5;
                // factor in the light color
                float4 color = float4(1.0, 1.0, 1.0, 1.0);
                output.diff = nl * color;

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                // sample main texture
                float4 col = tex2D(_MainTex, input.uv_texture.xy);
                
                col.rgb *= input.diff.rgb;
                                
                UNITY_APPLY_FOG(input.fogCoord, col);
                return col;
            }

            ENDCG
        }
    }
}