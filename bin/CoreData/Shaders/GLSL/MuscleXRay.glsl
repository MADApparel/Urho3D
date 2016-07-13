#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Fog.glsl"

varying vec2 vTexCoord;
varying vec4 vWorldPos;
varying vec3 vNormal;
#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetTexCoord(iTexCoord);
    vNormal = GetWorldNormal(modelMatrix);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));

    #ifdef VERTEXCOLOR
        vColor = iColor;
    #endif
}

void PS()
{
    // Get material diffuse albedo
    #ifdef DIFFMAP
        vec4 diffColor = cMatDiffColor * texture2D(sDiffMap, vTexCoord);
        #ifdef ALPHAMASK
            if (diffColor.a < 0.5)
                discard;
        #endif
    #else
        vec4 diffColor = cMatDiffColor;
    #endif

    #ifdef VERTEXCOLOR
        diffColor *= vColor;
    #endif

    // Get fog factor
    #ifdef HEIGHTFOG
        float fogFactor = GetHeightFogFactor(vWorldPos.w, vWorldPos.y);
    #else
        float fogFactor = GetFogFactor(vWorldPos.w);
    #endif
    
    //diffColor.rgb=vNormal
    vec3 cameraDir = normalize(vWorldPos.xyz - cCameraPosPS);
    float normaldp=1.0-abs(dot(cameraDir,vNormal));
    //diffColor.rgb=vNormal;
    
    

    #if defined(PREPASS)
        // Fill light pre-pass G-Buffer
        gl_FragData[0] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[1] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(DEFERRED)
    
    
        gl_FragData[0] = vec4(diffColor.rgb, 1.0f);
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
        gl_FragData[2] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[3] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(BACKFACING)
        float backdp=1.0-normaldp;
        float sidedp=normaldp*0.5+0.3;
        float backdpOut=backdp*0.5+0.3;
        vec4 diffColor1 = vec4(0.4,0.1,0.3,backdpOut);
        vec4 diffColor2 = vec4(0.9,0.3,0.3,sidedp);
        //vec4 outColor = vec4(diffColor1.r*normaldp+(1.0-normaldp)*diffColor2.r),diffColor1.g*normaldp+(1.0-normaldp)*diffColor2.g,diffColor1.b*normaldp+(1.0-normaldp)*diffColor2.b),backdpOut*normaldp+(1.0-normaldp)*sidedp);
        vec4 outColor=vec4(diffColor1.r*normaldp+(1.0-normaldp)*diffColor2.r,diffColor1.g*normaldp+(1.0-normaldp)*diffColor2.g,diffColor1.b*normaldp+(1.0-normaldp)*diffColor2.b,backdpOut*normaldp+(1.0-normaldp)*sidedp);
        gl_FragColor = outColor;
    #else
    float backdp=1.0-normaldp;
    float sidedp=normaldp*0.5+0.3;
    float backdpOut=backdp*0.5+0.3;
    vec4 diffColor1 = vec4(0.4,0.1,0.3,backdpOut);
    vec4 diffColor2 = vec4(0.9,0.3,0.3,sidedp);
    //vec4 outColor = vec4(diffColor1.r*normaldp+(1.0-normaldp)*diffColor2.r),diffColor1.g*normaldp+(1.0-normaldp)*diffColor2.g,diffColor1.b*normaldp+(1.0-normaldp)*diffColor2.b),backdpOut*normaldp+(1.0-normaldp)*sidedp);
    vec4 outColor=vec4(diffColor1.r*normaldp+(1.0-normaldp)*diffColor2.r,diffColor1.g*normaldp+(1.0-normaldp)*diffColor2.g,diffColor1.b*normaldp+(1.0-normaldp)*diffColor2.b,1.0);
    gl_FragColor = outColor;
#endif
}
