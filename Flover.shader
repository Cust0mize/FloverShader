Shader "ShaderDev/Flover" {
    Properties {
        _StebelColor("StebelColor", Color) = (1, 1, 1, 1)
        _MainTex("MainTex",2D) = "white" {}
        _OffsetStebel("OffsetStebel",Range(0,0.1)) = 1
        _Position("Position",Vector) = (0,0,0,0)

        [Header(Cloud)]
        _CloudColor("CloudColor", Color) = (1, 1, 1, 1)


        [Header(Bud)]
        _BudRadius("BudRadius",Range(0,0.5)) = 0.1
        _BudInsideOffset("BudInsideOffset",Range(0,0.5)) = 0.1
        _BudMainColor("BudColor", Color) = (1, 1, 1, 1)
        _BudInsideColor("BudInsideColor", Color) = (1, 1, 1, 1)

        [Header(Petals)]
        _PetalsRadius("PetalsRadius",Range(0,0.5)) = 0.1
        _PetalsXSize("PetalsXSize",Float) = 1
        _PetalsYSize("PetalsYSize",Float) = 1
        _PetalsCenterOffset("PetalsCenterOffset",Range(0,0.2)) = 0.1
        _PetalElementCount("PetalElementCount",Int) = 10
        _PetalsColor("PetalsColor", Color) = (1, 1, 1, 1)
    }

    SubShader {
        Blend SrcAlpha OneMinusSrcAlpha
        BlendOp Add
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        Pass {
            CGPROGRAM
            #pragma debug
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform half4 _StebelColor;
            uniform half4 _Position;
            uniform half _OffsetStebel;

            uniform half4 _BudMainColor;
            uniform half4 _BudInsideColor;
            uniform float _BudRadius;
            uniform float _BudInsideOffset;

            uniform float _PetalsRadius;
            uniform float _PetalsXSize;
            uniform float _PetalsYSize;
            uniform float _PetalElementCount;
            uniform float _PetalsCenterOffset;
            uniform half4 _PetalsColor;

            uniform half4 _CloudColor;

            struct VertexInfo {
                float4 vertex : POSITION;
                float4 texCoord : TEXCOORD0;
            };

            struct FragmentInfo {
                float4 position : SV_POSITION;
                float4 texCoord : TEXCOORD0;
            };

            FragmentInfo vert(VertexInfo vertexInfo) {
                FragmentInfo fragmentInfo;
                fragmentInfo.position = UnityObjectToClipPos(vertexInfo.vertex);
                fragmentInfo.texCoord.xy = (vertexInfo.texCoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                return fragmentInfo;
            }

            half4 DrawCircle(half2 uv, half4 color, half xSize, half ySize, half radius, half yOffset) {
                half squareCirclePoint = pow(uv.x * xSize, 2) + pow(uv.y * ySize - yOffset, 2);
                half radiusSqare = pow(radius, 2);

                if (squareCirclePoint < radiusSqare) {
                    return color;
                }

                return 0;
            }

            half4 DrawBud(half2 uv) {
                half4 budMainColor = DrawCircle(uv, _BudMainColor, 1, 1, _BudRadius, 0);
                half4 budInsideColor = DrawCircle(uv, _BudInsideColor, 1, 1, _BudRadius - _BudInsideOffset, 0);
                return lerp(budMainColor, budInsideColor, budInsideColor.a);
            }

            half4 DrawPetals(half2 uv, half addX, half addY, float radius) {
                half4 resultColor = _PetalsColor;
                resultColor.a = 0;
                half angle = (2 * 3.14) / _PetalElementCount;

                for (int i = 0; i < _PetalElementCount; i++) {
                    half currentAngleStep = angle * i;
                    half2 rotatedUV;
                    rotatedUV.x = uv.x * cos(currentAngleStep) - uv.y * sin(currentAngleStep);
                    rotatedUV.y = uv.x * sin(currentAngleStep) + uv.y * cos(currentAngleStep);
                    resultColor += DrawCircle(rotatedUV, _PetalsColor, addX, addY, radius, _PetalsCenterOffset);
                }

                return resultColor;
            }

            half4 DrawStebel(half4 originalUV) {
                half middleLow = 0.5 - _OffsetStebel;
                half middleHigh = 0.5 + _OffsetStebel;

                if (originalUV.x > middleLow && originalUV.x < middleHigh && originalUV.y < 0.6) {
                    return _StebelColor;
                }

                return 0;
            }

            half4 frag(FragmentInfo fragmentInfo) : COLOR {
                half4 offsetUV = fragmentInfo.texCoord + _Position;
                half4 originalUV = fragmentInfo.texCoord;
                half4 petalsColor = DrawPetals(offsetUV, _PetalsXSize, _PetalsYSize, _PetalsRadius);
                half4 budColor = DrawBud(offsetUV);
                half4 flowerColor = lerp(petalsColor, budColor, budColor.a);

                half4 cloudColor;
                cloudColor = DrawCircle(offsetUV, _CloudColor, 0.6, 1, 0.1, 0);


                half4 stebelColor = DrawStebel(originalUV);
                stebelColor = lerp(stebelColor, flowerColor, flowerColor.a);
                return stebelColor;
            }
            ENDCG
        }
    }
}