/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#ifndef __COOK_TORRANCE_BRDF__
#define __COOK_TORRANCE_BRDF__
#include "BRDF.cginc"

#define _D_GGX 1
#define _F_SCHLICK 1
#define _G_SMITH_SCHLICK_GGX 1

float3 Diffuse(float3 Albedo)
{
    return Albedo /PI;
}


float Item_D(float a, float NoH)
{
#if defined(_D_BLINNPHONG) 
    return D_Blinn(a, NoH);
#elif defined(_D_BECKMANN)
	return D_Beckmann(a, NoH);
#elif defined(_D_GGX)
	return D_GGX(a, NoH);
#endif
}

float Item_G(float a, float NoV, float NoL, float NoH, float VdH, float LoV)
{
#if defined(_VIS_NONE)
	return Vis_Implicit();
#elif defined(_VIS_NEUMANN)
	return Vis_Neumann(a, NoV, NoL);
#elif defined(_VIS_KELEMEN)
	return Vis_Kelemen(a, VdH);
#elif defined(_VIS_COOKTORRANCE)
	return Vis_CookTorrance(a, NoV, NoL, NoH, VdH);
#elif defined(_VIS_SMITH_BECKMANN)
	return Vis_Beckmann(a, NoV, NoL);
#elif defined(_VIS_SMITH_GGX)
	return Vis_Smith(a, NoV, NoL);
#elif defined(_VIS_SMITH_SCHLICK_GGX)
	return Vis_Schlick(a, NoV, NoL);
#elif defined(_VIS_GGX)
	return Vis_GGX(a, NoV, NoL);
#endif
}

float3 Item_F(float3 specularColor, float VoH)
{
#if defined(_F_NONE) 
	return F_None(specularColor);
#elif defined(_F_SCHLICK)
	return F_Schlick(specularColor, VoH);
#elif defined(_F_COOKTORRANCE)
	return F_CookTorrance(specularColor, VoH);
#endif
}
//-------------------------- BRDF -------------------------------------

float3 brdfCookTorrance(float3 albedoColor,float3 specularColor, float3 lightDir, float3 viewDir, float3 normal, float roughness)
{
    float3 H = normalize(lightDir + viewDir);
    float NoL = saturate(dot(normal, lightDir));
    float NoV = saturate(dot(normal, viewDir));
    float NoH = saturate(dot(normal, H));
    float VdH = saturate(dot(viewDir, H));
    float LoV = saturate(dot(lightDir, viewDir));

    float3 diff = Diffuse(albedoColor);
    
    float3 D = Item_D(roughness, NoH);
    float3 G = Item_G(roughness, NoV, NoL, NoH, VdH, LoV);
    float3 F = Item_F(specularColor, VdH);
            
    // Correction term according to 2013 Siggraph paper "rad"
    return  (diff * (1.0f - F) + D * G *  F) * NoL;
}

#endif //__COOK_TORRANCE_BRDF__