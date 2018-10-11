/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#include "BRDF.cginc"

half3 brdfClearCoat(half3 diffColor, half clearCoat, half3 specColor, half3 L, half3 V, half3 N, half Roughness, half3 ClearCoatNormal)
{
	half3 H = normalize(L + V);
	half NdotH = saturate(dot(N, H));
	half VdotH = saturate(dot(V, H));
	half NdotL = saturate(dot(N, L));
	half NdotV = saturate(dot(N, V));
	half LdotH = saturate(dot(L, H));

	half D = D_GGX(Roughness, NdotH);
	half Vis = Vis_SmithJointApprox(Roughness, NdotV, NdotL);
	half3 F = F_Schlick(specColor, VdotH);
	half3 spec1 = D * Vis * F;

	half D2 = D_GGX(Roughness, NdotH);
	half Vis2 = Vis_Kelemen(VdotH);
	float F2 = F_Schlick(0.04, 1.0, LdotH) * clearCoat;
	half3 spec2 = D2 * Vis2 * F2;

	half3 diff = 0;

	//No Energy compensation and absorption
	return (diff + spec1) * NdotL + spec2 * saturate(dot(ClearCoatNormal, L));
}
