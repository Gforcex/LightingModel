/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#ifndef __DESNEY_BRDF_CGINC
#define __DESNEY_BRDF_CGINC

// From Disney's BRDF explorer: https://github.com/wdas/brdf
float sqr(float x) { return x * x; }

float SchlickFresnel(float u)
{
	float m = clamp(1 - u, 0, 1);
	float m2 = m * m;
	return m2 * m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
	if (a >= 1) return 1 / PI;
	float a2 = a * a;
	float t = 1 + (a2 - 1)*NdotH*NdotH;
	return (a2 - 1) / (PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
	float a2 = a * a;
	float t = 1 + (a2 - 1)*NdotH*NdotH;
	return a2 / (PI * t*t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
	return 1 / (PI * ax*ay * sqr(sqr(HdotX / ax) + sqr(HdotY / ay) + NdotH * NdotH));
}

float smithG_GGX(float NdotV, float alphaG)
{
	float a = alphaG * alphaG;
	float b = NdotV * NdotV;
	return 1 / (NdotV + sqrt(a + b - a * b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
	return 1 / (NdotV + sqrt(sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV)));
}

//-------------------------- BRDF -------------------------------------
float3 brdfDisney(float3 baseColor, float roughness, float Metallic, 
			    float SpecularTint, float Specular,  float SheenTint, float Sheen, 
				float Anisotropic, float ClearcoatGloss, float Clearcoat,float Subsurface,
				float3 N, float3 L, float3 V, float3 X, float3 Y, 
				out float3 diffuseColor, out float3 specularColor )
{
	float NdotL = saturate(dot(N, L));
	float NdotV = saturate(dot(N, V));

    float3 H = normalize(L + V);
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float a = roughness * roughness;

	float3 Cdlin = baseColor;
    float Cdlum = 0.3f * Cdlin.x + 0.6f * Cdlin.y + 0.1f * Cdlin.z; // Cdlum approx.

    float3 Ctint = Cdlum > 0.0f ? Cdlin /Cdlum : 1.0f.xxx; // Normalize Cdlum to isolate hue+sat.
    float3 Cspec0 = lerp(Specular * 0.08f * lerp(1.0f.xxx, Ctint, SpecularTint), Cdlin, Metallic);
    float3 CSheen = lerp(1.0f.xxx, Ctint, SheenTint);

    // Diffuse fresnel - go from 1 at N incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    float FL = SchlickFresnel(NdotL);
    float FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5f + 2.0f * LdotH * LdotH * a;
    float Fd = lerp(1.0f, Fd90, FL) * lerp(1.0f, Fd90, FV);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH * LdotH * a;
    float Fss = lerp(1.0f, Fss90, FL) * lerp(1.0f, Fss90, FV);
    float ss = 1.25f * (Fss * (1.0f / (NdotL + NdotV + 0.0001f) - 0.5f) + 0.5f);
	
    // specular
    float aspect = sqrt(1.0f - Anisotropic*0.9f);
    float ax = max(0.001f, sqr(a)/aspect);
    float ay = max(0.001f, sqr(a)*aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    float FH = SchlickFresnel(LdotH);
    float3 Fs = lerp(Cspec0, 1.0f.xxx, FH);
    float roughg = sqr(a*0.5f+0.5f);
    //float Gs = smithG_GGX(NdotL, roughg) * smithG_GGX(NdotV, roughg);
	float Gs = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay) * smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);

    // sheen
    float3 Fsheen = FH * Sheen * CSheen;

    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, lerp(0.1f, 0.001f, ClearcoatGloss));
    float Fr = lerp(0.04f, 1.0f, FH);
    float Gr = smithG_GGX(NdotL, 0.25f) * smithG_GGX(NdotV, 0.25f);
    
	specularColor = Cspec0;
	diffuseColor = (lerp(Fd, ss, Subsurface) * Cdlin + Fsheen) * (1.0f - Metallic);

	return ((1 / PI) * lerp(Fd, ss, Subsurface)*Cdlin + Fsheen)
		* (1 - Metallic)
		+ Gs * Fs*Ds + .25*Clearcoat*Gr*Fr*Dr;
}

#endif //__DESNEY_BRDF_CGINC