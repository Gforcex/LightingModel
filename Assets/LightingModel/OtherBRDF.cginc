/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/
#ifndef __BRDF_G_ITEM_CGINC_
#define __BRDF_G_ITEM_CGINC_

//ref: Disney's BRDF explorer: https://github.com/wdas/brdf
//-----------------------------------------------------------------------------
// D  Iterm
//-----------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// Exponential distribution
// normalization constant
// 1/Integrate[Exp[-(x/c)] Cos[x] Sin[x], {x, 0, Pi/2}, {phi, 0, 2 Pi} , Assumptions -> c > 0]
// == (1 + 4 c^2)/(2 c^2 (1 + Exp[-(Pi/(2 c))]) Pi)
float D_Exponential( float NdotH, float Roughness)
{
	float a = Roughness;
	float a2 = a * a;

    float D = exp( -acos(NdotH) / a);
    D *= (1 + 4* a2)/(2* a2*(1 + exp(-(UNITY_PI/(2* a))))*UNITY_PI); //normalized
    return D;
}

// ---------------------------------------------------------------------------------
// Nishino 2009, "Directional Statistic BRDF Model"
// (Hemi-EPD = hemispherical exponential power distribution)
float D_Nishino(float NdotH, float k, float n)
{
    // note: k in Nishino is assumed negative - negate as used instead
    float epd = 1-exp(-k * pow(NdotH,n));
    // the normalization constant includes gamma functions which are unavailable in glsl
    // float Cn =  pow(n*k,1/n) / (gamma(1/n) - igamma(1/n, k) - pow(n*k, 1/n))
    // some approximation is needed
    float Cn = 1;

    return (Cn*epd);
}

//-----------------------------------------------------------------------------
// Vis Iterm
//-----------------------------------------------------------------------------

// -------------------------------------------------------------------------
// [Ashikhmin Shirley 2000, An Isotropic BRDF Model]
float Vis_AshikhminShirley(float NdotL, float NdotV, float LdotH)
{
	return 1 / (4 * LdotH * max(NdotL, NdotV));
}

// [Ashikhmin Premoze 2007, Distribution-based BRDFs]
float Vis_AshikhminPremoze( float NdotL, float NdotV, float LdotH )
{
	return 0.25 / (NdotL + NdotV - NdotL * NdotV);
}

// -------------------------------------------------------------------------
// Ward 92
float Vis_Ward( float NdotL, float NdotV )
{
    return 1/(4 * sqrt(NdotL * NdotV));
}

// -------------------------------------------------------------------------
// [Walter07 G term (from GGX distribution)]
float Vis_Walter( float NdotL, float NdotV , float alphaG)
{
	half G1 = 2/(1 + sqrt(1 + alphaG*alphaG * (1-NdotL*NdotL)/(NdotL*NdotL)));
	half G2 = 2/(1 + sqrt(1 + alphaG*alphaG * (1-NdotV*NdotV)/(NdotV*NdotV)));
    float G = G1 * G2;
    return G / (4 * NdotL*NdotV);
}

// -------------------------------------------------------------------------
// [Kurt10, An Anisotropic BRDF Model for Fitting and Monte Carlo Rendering]
float Vis_Kurt(float LdotH, float NdotL, float NdotV, float Roughness)
{
	return 1 / (4 * LdotH * pow(NdotL* NdotV, Roughness));
}

// -------------------------------------------------------------------------
// [Duer 2010 Bounding the Albedo of the Ward Reflectance Model]
float Vis_Duer( float3 H, float NdotL, float NdotV, float NdotH)
{
    float G = dot(H,H) * pow(NdotH,-4);
    return G / (4 * NdotL * NdotV);
}

#endif //_BRDF_G_ITEM_CGINC_