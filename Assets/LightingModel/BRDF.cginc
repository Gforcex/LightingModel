/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#ifndef __BRDF_CGINC__
#define __BRDF_CGINC__
#include "Math.cginc"

//ref: Unreal Engine 4, Unity3D and others 

// Physically based shading model
// parameterized with the below options

// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
// Vis = G / (4*NoL*NoV)

//-----------------------------------------------------------------------------
// D Iterm
//-----------------------------------------------------------------------------
//**** In UE4, Roughness = Roughness * Roughness;

// [Blinn 1977, "Models of light reflection for computer synthesized pictures"]
float D_Blinn( float Roughness, float NoH )
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float n = 2 / a2 - 2;
	return (n+2) / (2*PI) * pow( NoH, n );		// 1 mad, 1 exp, 1 mul, 1 log
}

// BlinnPhong normalized as reflection density function (RDF)
// ready for use directly as specular: spec=D
// http://www.thetenthplanet.de/archives/255
inline half D_RDFBlinnPhong( float Roughness, float NoH )
{
	half n = Roughness; //??? with same above?
	return (n+2) / (8*PI) * pow (NoH, n);
}

// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
float D_Beckmann( float Roughness, float NoH )
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float NoH2 = NoH * NoH;
	return exp( (NoH2 - 1) / (a2 * NoH2) ) / ( PI * a2 * NoH2 * NoH2 );
}

half D_PHBeckmann( half Roughness, half NoH ) 
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	half alpha = cos( NoH );
	half ta = tan( alpha );
	return 1 /( a2 * pow( NoH, 4 ) ) * exp(-( ta * ta ) / ( a2 ));
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
half D_GGX( half Roughness, half NoH )
{
	half a = Roughness * Roughness;
	half a2 = a * a;
	half d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
	return a2 / ( UNITY_PI * d * d + 1e-5f);					// 4 mul, 1 rcp

	////GGX [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
	//float NoH2 = NoH * NoH;
	//float d = NoH2 * (a2 + (1 - NoH2) / NoH2);
	//return a2 / (UNITY_PI * d * d + 1e-5f);
}


float D_Gaussian(float Roughness, float NoH)
{
	float a = Roughness * Roughness;
	float thetaH = acos(NoH);
	return exp(-thetaH * thetaH / a);
}

//-----------------------------------------------------------------------------
// Aniso D Iterm
//-----------------------------------------------------------------------------
// X -> roughness in tangent direction
// Y -> roughness in bitangent direction

// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
float D_GGXaniso( float RoughnessX, float RoughnessY, float NoH, float3 H, float3 X, float3 Y )
{
	float ax = RoughnessX * RoughnessX;
	float ay = RoughnessY * RoughnessY;
	float XoH = dot( X, H );
	float YoH = dot( Y, H );
	float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
	return 1 / ( PI * ax*ay * d*d );
}

float D_WardAniso(float RoughnessX, float RoughnessY, float NoL, float NoV, float NoH, float3 H, float3 X, float3 Y)
{
	float ax = RoughnessX * RoughnessX;
	float ay = RoughnessY * RoughnessY;
	float XoH = dot(X, H);
	float YoH = dot(Y, H);

	float d = ((XoH*XoH) / (ax*ax) + (YoH * YoH) / (ay*ay)) / (NoH * NoH);
	return exp(-d) / (4 * PI * ax * ay * sqrt(NoL * NoV));
}
//-----------------------------------------------------------------------------
// G Iterm
// 1 / ( 4 * NoV * NoL) 包括在内
//-----------------------------------------------------------------------------

float Vis_Implicit()
{
	return 0.25;
}

// [Neumann et al. 1999, "Compact metallic reflectance models"]
float Vis_Neumann( float NoV, float NoL )
{
	return 1 / ( 4 * max( NoL, NoV ) );
}

// [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
// Kelemen-Szirmay-Kalos is an approximation to Cook-Torrance visibility term
// http://sirkan.iit.bme.hu/~szirmay/scook.pdf
float Vis_Kelemen( float VoH )
{
	// constant to prevent NaN
	return rcp( 4 * VoH * VoH + 1e-5);
}

//Modified Kelemen-Szirmay-Kalos which takes roughness into account, based on: http://www.filmicworlds.com/2014/04/21/optimizing-ggx-shaders-with-dotlh/ 
half Vis_ModifiedKelemen(half LdotH, half Roughness)
{
	//form Unity
	half c = 0.797884560802865; // c = sqrt(2 / Pi)
	half k = Roughness * Roughness * c;
	half gH = LdotH * (1-k) + k;
	half res = 1.0 / (gH * gH);
	return res / 4; //Unity -> UE4

	//float gH = NdotV * k + (1 - k);
	//return (gH * gH * NdotL)/( 4 * NdotL * NdotV);
}

//Schlick-GGX
// Tuned to match behavior of Vis_Smith
// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
float Vis_Schlick( float Roughness, float NoV, float NoL )
{
	float k = Roughness * Roughness * 0.5;
	float Vis_SchlickV = NoV * (1 - k) + k;
	float Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}

// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointApprox(float Roughness, float NoV, float NoL)
{
	float a = Roughness * Roughness;
	float Vis_SmithV = NoL * (NoV * (1 - a) + a);
	float Vis_SmithL = NoV * (NoL * (1 - a) + a);
	// Note: will generate NaNs with Roughness = 0.  MinRoughness is used to prevent this
	return 0.5 * rcp(Vis_SmithV + Vis_SmithL + 1e-5f);
}

// [Hammon 2017, "PBR Diffuse Lighting for GGX+Smith Microsurfaces"]
float Vis_SmithGGXCorrelatedFast(float Roughness, float NoV, float NoL) {
	return 0.5 / lerp(2.0 * NoL * NoV, NoL + NoV, Roughness);
}

//Schlick-Beckmann
//From Unity, Smith-Schlick derived for Beckmann
half Vis_SmithBeckmann( float Roughness, float NoV, float NoL )
{
	half c = 0.797884560802865h; // c = sqrt(2 / Pi)
    half k = Roughness * c;

	float Vis_SchlickV = NoV * (1 - k) + k;
	float Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL + 1e-5f);
}

// Smith term for GGX
// [Smith 1967, "Geometrical shadowing of a random rough surface"]
float Vis_Smith( float Roughness, float NoV, float NoL )
{
	float a = Roughness * Roughness;
	float a2 = a*a;

	float Vis_SmithV = NoV + sqrt( NoV * (NoV - NoV * a2) + a2 );
	float Vis_SmithL = NoL + sqrt( NoL * (NoL - NoL * a2) + a2 );
	return 1/( Vis_SmithV * Vis_SmithL );

	//float Vis_SmithV = NoV * sqrt(NoV * (NoV - NoV * a2) + a2);
	//float Vis_SmithL = NoL * sqrt(NoL * (NoL - NoL * a2) + a2);
	//return 1 / (Vis_SmithV + Vis_SmithL);
}

//[Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float Vis_GGX(float Roughness, float NoV, float NoL)
{
	//https://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
	float a = Roughness * Roughness;
	float a2 = a * a;

	float d = a2 + (1 - a2) * NoV * NoV;
	//float G = (2 * NoV) / (NoV + sqrt(d));
	return 0.5 / ((NoV + sqrt(d)) * NoL);
}

// Torrance-Sparrow G term (from Cook-Torrance)
// Cook-Torrance visibility term, doesn't take roughness into account
half Vis_CookTorrance (half NdotV, half NdotL, half NdotH, half VdotH)
{
	VdotH += 1e-5f;
	half G = min (1.0, min (
		(2.0 * NdotH * NdotV) / VdotH,
		(2.0 * NdotH * NdotL) / VdotH));
	return G / (NdotL * NdotV + 1e-4f);

	//优化
	//return min(1, 2 * (NdotH / VdotH) * min(NdotL, NdotV)) / (NdotL * NdotV + 1e-4f);
}

float Vis_Beckmann(float Roughness, float NoV, float NoL)
{
	half a = Roughness * Roughness;
	
	float G1;
    float a1 = NoV / ( a * sqrt(1.0f - NoV * NoV));
    if ( a1 >= 1.6f ) {  
        G1 = 1.0f;
    }
    else {
        float c2 = a1 * a1;
        G1 = (3.535f * a1 + 2.181f * c2) / ( 1 + 2.276f * a1 + 2.577f * c2);
    }
	
	float G2;
	float a2 = NoL / ( a * sqrt(1.0f - NoL * NoL));
    if ( a2 >= 1.6f ) {   
        G2 = 1.0f;
    }
	else {  
        float c2 = a2 * a2;
        G2 = (3.535f * a2 + 2.181f * c2) / ( 1 + 2.276f * a2 + 2.577f * c2);
    }
    
	return G1 * G2 / ( 4 * NoL* NoV );
}
//-----------------------------------------------------------------------------
// Aniso G Iterm
//-----------------------------------------------------------------------------
// Ref: https://cedec.cesa.or.jp/2015/session/ENG/14698.html The Rendering Materials of Far Cry 4
// Note: V = G / (4 * NdotL * NdotV)
float V_SmithJointGGXAniso(float TdotV, float BdotV, float NdotV, float TdotL, float BdotL, float NdotL, float roughnessT, float roughnessB)
{
    float aT = roughnessT;
    float aT2 = aT * aT;
    float aB = roughnessB;
    float aB2 = aB * aB;

    float lambdaV = NdotL * sqrt(aT2 * TdotV * TdotV + aB2 * BdotV * BdotV + NdotV * NdotV);
    float lambdaL = NdotV * sqrt(aT2 * TdotL * TdotL + aB2 * BdotL * BdotL + NdotL * NdotL);

    return 0.5 / (lambdaV + lambdaL);
}


// Inline D_GGXAniso() * V_SmithJointGGXAniso() together for better code generation.
float DV_SmithJointGGXAniso(float TdotH, float BdotH, float NdotH,
                            float TdotV, float BdotV, float NdotV,
                            float TdotL, float BdotL, float NdotL,
                            float roughnessT, float roughnessB, float partLambdaV)
{
    float aT2 = roughnessT * roughnessT;
    float aB2 = roughnessB * roughnessB;

    float  f = TdotH * TdotH / aT2 + BdotH * BdotH / aB2 + NdotH * NdotH;
    float2 D = float2(1, roughnessT * roughnessB * f * f); // Fraction without the constant (1/Pi)

    float lambdaV = NdotL * partLambdaV;
    float lambdaL = NdotV * sqrt(aT2 * TdotL * TdotL + aB2 * BdotL * BdotL + NdotL * NdotL);

    float2 G = float2(1, lambdaV + lambdaL);               // Fraction without the constant (0.5)

    return (INV_PI * 0.5) * (D.x * G.x) / (D.y * G.y);
}

//-----------------------------------------------------------------------------
// Fresnel term
//-----------------------------------------------------------------------------

float3 F_None( float3 SpecularColor )
{
	return SpecularColor;
}

half3 F_Schlick(half3 f0, half3 f90, half VoH)
{
    half x  = 1.0 - VoH;
    half x2 = x * x;
    half x5 = x * x2 * x2;
    return f0 * (1.0 - x5) + (f90 * x5);        // sub mul mul mul sub mul mad*3

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	//return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
half3 F_Schlick(half3 f0, half VoH)
{
    return F_Schlick(f0, 1.0, VoH);               // sub mul mul mul sub mad
}

//Cook and Torrance 1982, "A Reflectance Model for Computer Graphics"
float3 F_CookTorrance( float3 SpecularColor, float VoH )
{
	//F02Ior
	float3 SpecularColorSqrt = sqrt( clamp( float3(0, 0, 0), float3(0.99, 0.99, 0.99), SpecularColor ) );
	float3 n = ( 1 + SpecularColorSqrt ) / ( 1 - SpecularColorSqrt ); 
	//fresnel
	float3 g = sqrt( n*n + VoH*VoH - 1 );
	return 0.5 * Square( (g - VoH) / (g + VoH) ) * ( 1 + Square( ((g+VoH)*VoH - 1) / ((g-VoH)*VoH + 1) ) );
}

// Ref: https://seblagarde.wordpress.com/2013/04/29/memo-on-fresnel-equations/
// Fresnel dieletric / conductor
// Note: etak2 = etak * etak (optimization for Artist Friendly Metallic Fresnel below)
// eta = eta_t / eta_i and etak = k_t / n_i
float3 F_FresnelConductor(float3 eta, float3 etak2, float cosTheta)
{
	float cosTheta2 = cosTheta * cosTheta;
	float sinTheta2 = 1.0 - cosTheta2;
	float3 eta2 = eta * eta;

	float3 t0 = eta2 - etak2 - sinTheta2;
	float3 a2plusb2 = sqrt(t0 * t0 + 4.0 * eta2 * etak2);
	float3 t1 = a2plusb2 + cosTheta2;
	float3 a = sqrt(0.5 * (a2plusb2 + t0));
	float3 t2 = 2.0 * a * cosTheta;
	float3 Rs = (t1 - t2) / (t1 + t2);

	float3 t3 = cosTheta2 * a2plusb2 + sinTheta2 * sinTheta2;
	float3 t4 = t2 * sinTheta2;
	float3 Rp = Rs * (t3 - t4) / (t3 + t4);

	return 0.5 * (Rp + Rs);
}

half3 F_SchlickApproximation(half3 f0, half NoH)
{
//	Fresnel: Schlick / fast fresnel approximation
	#define OneOnLN2_x6 8.656170
	return f0 + ( 1.0h - f0) * exp2(-OneOnLN2_x6 * NoH );
}

half F_SebastienLagarde(half VoH)
{
    return exp2((-5.55473h * VoH - 6.98316h) * VoH);
}

half F_SphericalGaussian(half3 F0, half VoH)
{
	return F0 + (1 - F0)  * pow(2, ((-5.55473 * VoH) - 6.98316) * VoH);
}

half3 F_LazarovFresnelTerm (half3 F0, half roughness, half VoH)
{
	half t = Pow5 (1 - VoH);	// ala Schlick interpoliation
	t /= 4 - 3 * roughness;
	return F0 + (1-F0) * t;
}
half3 F_SebLagardeFresnelTerm (half3 F0, half roughness, half VoH)
{
	half t = Pow5 (1 - VoH);	// ala Schlick interpoliation
	return F0 + (max (F0, roughness) - F0) * t;
}

//---------------------
// F0 / IOR
//---------------------

float Ior2F0(float ior) 
{
	const float incidentIor = 1;
	float r = (ior - incidentIor) / (ior + incidentIor);
	return r * r;
}

float F02Ior(float f0) 
{
	float r = sqrt(f0);
	return (1.0 + r) / (1.0 - r);
}
//---------------
// EnvBRDF
//---------------

sampler2D		PreIntegratedGF;

half3 EnvBRDF( half3 SpecularColor, half Roughness, half NoV )
{
	// Importance sampled preintegrated G * F
	float2 AB = tex2D( PreIntegratedGF, float2( NoV, Roughness )).rg;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
	float3 GF = SpecularColor * AB.x + saturate( 50.0 * SpecularColor.g ) * AB.y;
	return GF;
}

half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

#if !(ES2_PROFILE || ES3_1_PROFILE)
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// In ES2 this is skipped for performance as the impact can be small
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate( 50.0 * SpecularColor.g );
#endif

	return SpecularColor * AB.x + AB.y;
}

half EnvBRDFApproxNonmetal( half Roughness, half NoV )
{
	// Same as EnvBRDFApprox( 0.04, Roughness, NoV )
	const half2 c0 = { -1, -0.0275 };
	const half2 c1 = { 1, 0.0425 };
	half2 r = Roughness * c0 + c1;
	return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
}

//-----------------------------------------------------------------------------
// D_Inv Iterm for Cloth
//-----------------------------------------------------------------------------

float D_InvBlinn( float Roughness, float NoH )
{
	float m = Roughness * Roughness;
	float m2 = m * m;
	float A = 4;
	float Cos2h = NoH * NoH;
	float Sin2h = 1 - Cos2h;
	//return rcp( PI * (1 + A*m2) ) * ( 1 + A * ClampedPow( Sin2h, 1 / m2 - 1 ) );
	return rcp( PI * (1 + A*m2) ) * ( 1 + A * exp( -Cos2h / m2 ) );
}

float D_InvBeckmann( float Roughness, float NoH )
{
	float m = Roughness * Roughness;
	float m2 = m * m;
	float A = 4;
	float Cos2h = NoH * NoH;
	float Sin2h = 1 - Cos2h;
	float Sin4h = Sin2h * Sin2h;
	return rcp( PI * (1 + A*m2) * Sin4h ) * ( Sin4h + A * exp( -Cos2h / (m2 * Sin2h) ) );
}

// Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
float D_InvGGX( float Roughness, float NoH )
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float A = 4;
	float d = ( NoH - a2 * NoH ) * NoH + a2;
	return rcp( PI * (1 + A*a2) ) * ( 1 + 4 * a2*a2 / ( d*d ) );
}

// Ashikhmin 2007, "Distribution-based BRDFs"
float D_Ashikhmin(float Roughness, float NoH) {
	float a2 = Roughness * Roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
float D_Charlie(float Roughness, float NoH) {
	float invAlpha = 1.0 / Roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

// Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
float Vis_Cloth(float NoV, float NoL) //Vis_Neubelt
{
	return rcp(4 * (NoL + NoV - NoL * NoV));
}

//from : Unity3D
float CharlieL(float x, float r)
{
	r = saturate(r);
	r = 1.0 - (1.0 - r) * (1.0 - r);

	float a = lerp(25.3245, 21.5473, r);
	float b = lerp(3.32435, 3.82987, r);
	float c = lerp(0.16801, 0.19823, r);
	float d = lerp(-1.27393, -1.97760, r);
	float e = lerp(-4.85967, -4.32054, r);

	return a / (1. + b * pow(abs(x), c) ) + d * x + e;
}

// Note: This version don't include the softening of the paper: Production Friendly Microfacet Sheen BRDF
float Vis_Charlie(float NdotL, float NdotV, float roughness)
{
	float lambdaV = NdotV < 0.5 ? exp(CharlieL(NdotV, roughness)) : exp(2.0 * CharlieL(0.5, roughness) - CharlieL(1.0 - NdotV, roughness));
	float lambdaL = NdotL < 0.5 ? exp(CharlieL(NdotL, roughness)) : exp(2.0 * CharlieL(0.5, roughness) - CharlieL(1.0 - NdotL, roughness));

	return 1.0 / ((1.0 + lambdaV + lambdaL) * (4.0 * NdotV * NdotL));
}

#endif //__BRDF_CGINC__