/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#include "BRDF.cginc"

// Energy conserving wrap diffuse term, does *not* include the divide by pi
float DiffuseWarp(float NoL, float w) 
{
	return saturate((NoL + w)/((1.0 + w)*(1.0 + w)));
}

half3 brdfClothAshikhmin(half3 diffColor, half3 subsurfaceColor, half3 specColor, half3 L, half3 V, half3 N, half Roughness)
{
	half3 H = normalize(L + V);
	half NdotH = saturate(dot(N, H));
	half VdotH = saturate(dot(V, H));
	half NdotL = saturate(dot(N, L));
	half NdotV = saturate(dot(N, V));
	half LdotH  = saturate(dot(L, H));

	half D = D_Ashikhmin(Roughness, NdotH);
	//half D = D_Charlie(Roughness, NdotH);
	half Vis = Vis_Cloth(NdotV, NdotL);
	half3 F = F_Schlick(specColor, VdotH);

	half3 spec = D * Vis * F;

	half3 diff = Diffuse_Burley(diffColor, Roughness, NdotV, NdotL, VdotH);

#ifndef _SUBSURFACE_COLOR
	return (diff + spec) * NdotL;
#else
	diff *= DiffuseWarp(dot(N, L), 0.5); // Energy conservative wrap diffuse to simulate subsurface scattering
										  //The Order: 1886 , Used diffuse Fresnel term

	// Cheap subsurface scatter
	diff *= saturate(subsurfaceColor + NdotL);
	return diff + spec * NdotL;
#endif
}


half3 brdfClothCharlie(half3 diffColor, half3 subsurfaceColor, half3 specColor, half3 L, half3 V, half3 N, half Roughness)
{
	half3 H = normalize(L + V);
	half NdotH = saturate(dot(N, H));
	half VdotH = saturate(dot(V, H));
	half NdotL = saturate(dot(N, L));
	half NdotV = saturate(dot(N, V));
	half LdotH = saturate(dot(L, H));

	//half D = D_Ashikhmin(Roughness, NdotH);
	half D = D_Charlie(Roughness, NdotH);
	half Vis = Vis_Cloth(NdotV, NdotL);
	half3 F = F_Schlick(specColor, VdotH);

	half3 spec = D * Vis * F;

	float3 diff = Diffuse_Burley(diffColor, Roughness, NdotV, NdotL, VdotH);
	
#ifndef _SUBSURFACE_COLOR
		return (diff + spec) * NdotL;
#else
		diff *= DiffuseWarp(dot(N, L), 0.5); // Energy conservative wrap diffuse to simulate subsurface scattering
											  //The Order: 1886 , Used diffuse Fresnel term

											  // Cheap subsurface scatter
	diff *= saturate(subsurfaceColor + NdotL);
	return diff + spec * NdotL;
#endif
}

half3 brdfClothUE4(half3 diffColor, half3 FuzzColor, half Cloth, half3 specColor, half3 L, half3 V, half3 N, half Roughness)
{
	half3 H = normalize(L + V);
	half NdotH = saturate(dot(N, H));
	half VdotH = saturate(dot(V, H));
	half NdotL = saturate(dot(N, L));
	half NdotV = saturate(dot(N, V));
	half LdotH = saturate(dot(L, H));

	float D1 = D_GGX(Roughness, NdotH);
	float Vis1 = Vis_SmithJointApprox(Roughness, NdotV, NdotL);
	float3 F1 = F_Schlick(specColor, VdotH);
	float3 spec1 = (D1 * Vis1) * F1;

	// Cloth - Asperity Scattering - Inverse Beckmann Layer
	float D2 = D_InvGGX(Roughness, VdotH);
	float Vis2 = Vis_Cloth(NdotV, NdotL);
	float3 F2 = F_Schlick(FuzzColor, VdotH);
	float3 spec2 = (D2 * Vis2) * F2;
	float3 spec = lerp(spec1, spec2, Cloth);

	float3 diff = Diffuse_Lambert(diffColor);
	
	return (diff + spec) * NdotL;
}

