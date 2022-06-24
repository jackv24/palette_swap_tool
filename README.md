# Palette Swap Tool

A simple tool for generating palette swap LUTs for use in palette swap shaders, etc.

## Example Unity shader

The tool outputs images that have LUT UVs encoded in the Red and Green channels. A shader can be used to apply the colours in the LUTs back to the sprite.

### Fragment Shader snippet

```Shaderlab
fixed4 tintColor = IN.color;
fixed4 spriteColor = SampleSpriteTexture(IN.texcoord);
fixed4 swappedColor = tex2D(_SwapTex, float2(spriteColor.r, 1 - spriteColor.g));

fixed4 c = swappedColor;
c.a = spriteColor.a;
c *= tintColor;
c.rgb = lerp(c.rgb, _FlashColor.rgb, _FlashAmount);
c.rgb *= c.a;

return c;
```

### Full Shader Example

```Shaderlab
Shader "Sprites/Default-PaletteSwap"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [PerRendererData] _SwapTex("Palette LUT", 2D) = "white" {}
        [MaterialToggle] PixelSnap("Pixel snap", Float) = 0
        [HideInInspector] _RendererColor("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha("Enable External Alpha", Float) = 0
        [PerRendererData] _FlashColor("Flash Color", Color) = (1,1,1,1)
        [PerRendererData] _FlashAmount("Flash Amount", Range(0,1)) = 0
    }

        SubShader
        {
            Tags
            {
                "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
                "PreviewType" = "Plane"
                "CanUseSpriteAtlas" = "True"
            }

            Cull Off
            Lighting Off
            ZWrite Off
            Blend One OneMinusSrcAlpha

            Pass
            {
            CGPROGRAM
                #pragma vertex SpriteVert
                #pragma fragment SwapSpriteFrag
                #pragma target 2.0
                #pragma multi_compile_instancing
                #pragma multi_compile _ PIXELSNAP_ON
                #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
                #include "UnitySprites.cginc"

                sampler2D _SwapTex;

                fixed4 _FlashColor;
                float _FlashAmount;

                fixed4 SwapSpriteFrag(v2f IN) : SV_Target
                {
                    fixed4 tintColor = IN.color;
                    fixed4 spriteColor = SampleSpriteTexture(IN.texcoord);
                    fixed4 swappedColor = tex2D(_SwapTex, float2(spriteColor.r, 1 - spriteColor.g));

                    fixed4 c = swappedColor;
                    c.a = spriteColor.a;
                    c *= tintColor;
                    c.rgb = lerp(c.rgb, _FlashColor.rgb, _FlashAmount);
                    c.rgb *= c.a;

                    return c;
                }
                ENDCG
            }
        }
}
```
