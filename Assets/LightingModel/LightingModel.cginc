/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

#ifndef __LIGHTING_MODEL_CGINC
#define __LIGHTING_MODEL_CGINC
#include "BRDF.cginc"
#include "OtherBRDF.cginc"
//---------------------------------------------------------------------------------

half3 brdfPhong( half3 specColor, half3 L, half3 V, half3 N, half Shininess)
{
    half3 R = reflect(L,N);
    half spec = pow(max(0, dot(R,V)), Shininess);

    return specColor * spec * max(0.0, dot(N, L));
}

//---------------------------------------------------------------------------------

half3 brdfBlinnphong(half3 specColor, half3 L, half3 V, half3 N, half Shininess)
{
    half3 H = normalize(L+V);
    half spec = pow(max(0,dot(N,H)), Shininess);

    return specColor * spec * max(0.0, dot(N, L));
}

//---------------------------------------------------------------------------------

half3 brdfModifiedphong( half3 specColor, half3 L, half3 V, half3 N, half Roughness )
{
    half3 R = reflect(L,N);
	half NdotL = max(0, dot(N, L));

    // specular
    half norm = (Roughness+2)/(2*UNITY_PI);
    half spec = norm * pow(max(0, dot(R,V)), Roughness);
    return specColor * spec * (NdotL);
}

//---------------------------------------------------------------------------------
// "Stretched Phong" BRDF from "Compact Metallic Reflectance Models", Neumann et al. 1999

half3 brdfStretchedphong(half3 specColor, half3 L, half3 V, half3 N, half Roughness )
{
    half norm = (Roughness+2)/(2*UNITY_PI);
    half NdotL = dot(N,L);
    half NdotV = dot(N,V);
    half LdotV = dot(L,V);

    half spec = norm * pow(max(0, 2 * NdotL * NdotV - LdotV), Roughness) / pow(max(NdotL, NdotV), Roughness);
    return specColor * spec;
}

//---------------------------------------------------------------------------------

//Blinn implementation of Torrance-Sparrow
half3 brdfBlinn( half3 specColor, half3 L, half3 V, half3 N, half Roughness )
{
	half3 H = normalize(L+V);
    half NdotH = saturate( dot(N, H) );
	half VdotH = saturate( dot(V, H) );
	half NdotL = saturate( dot(N, L) );
	half NdotV = saturate( dot(N, V) );

    half D = D_Blinn(Roughness, NdotH);
	half Vis = Vis_CookTorrance (NdotL, NdotV, NdotH, VdotH);
	half3 F =  F_CookTorrance( specColor, VdotH);

    return D * Vis * F * NdotL;
}

//---------------------------------------------------------------------------------

half3 brdfCooktorrance(half3 specColor, half3 L, half3 V, half3 N, half Roughness )
{
    half3 H = normalize( L + V );
    half NdotH = saturate( dot(N, H) );
    half VdotH = saturate( dot(V, H) );
    half NdotL = saturate( dot(N, L) );
    half NdotV = saturate( dot(N, V) );

    half D = D_Beckmann(Roughness, NdotH);
    half3 F = F_Schlick(specColor, VdotH);
	half Vis = Vis_CookTorrance (NdotL, NdotV,  NdotH, VdotH);
    
    return D * Vis * F * NdotL;
}

//---------------------------------------------------------------------------------

half3 brdfDisneyAniso(half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y, half Roughness )
{
	half NdotL = max(0, dot(N, L));
    half3 T = X; //Y
    half glossiness = 1 / (Roughness + 1e-5f);
    half LdotN = dot(L,N);
    half lightAngle = acos(LdotN);
    half cosAngleLT = dot(L,T);
    half sinAngleLT = sqrt(1 - (cosAngleLT * cosAngleLT));
    half cosAngleVT = dot(V,T);
    half spec = pow(((sinAngleLT * sqrt(1 - (cosAngleVT * cosAngleVT)))
                      - (cosAngleLT * cosAngleVT)),
                     glossiness);

    return specColor * spec * (NdotL);
}
//---------------------------------------------------------------------------------

half3 brdfKajiya(half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y, half Roughness)
{
	half NdotL = max(0, dot(N, L));
    half3 T = X; //Y
    half glossiness = 1 / (Roughness + 1e-5f);
    half LdotN = dot(L,N);
    half lightAngle = acos(LdotN);
    half cosAngleLT = dot(L,T);
    half sinAngleLT = sqrt(1 - (cosAngleLT * cosAngleLT));
    half cosAngleVT = dot(V,T);

    half3 R = reflect(L,N);
    half t = acos(dot(L,T)) - acos(dot(R,T));
    half spec = pow(cos(t), glossiness);

    return specColor * spec * (NdotL);
}

//---------------------------------------------------------------------------------
//Ashikhmin Shirley 2000 - Anisotropic phong reflectance model
//AnisoRoughness Range( 1000 100 )
half3 brdfAshikhmanShirley(half3 diffColor, half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y , half2 AnisoRoughness) 
{
    half3 H = normalize(L+V);
    half HdotV = dot(H,V);
    half HdotX = dot(H,X);
    half HdotY = dot(H,Y);
    half NdotH = dot(N,H);
    half NdotV = dot(N,V);
    half NdotL = dot(N,L);
    
	//dfiffuse
    half3 diffuse = 28/(23*UNITY_PI) * diffColor * (1-pow(1-NdotV/2, 5)) * (1-pow(1-NdotL/2, 5));
    diffuse *= (1-specColor);

	//specular
	half3 F = F_Schlick(specColor, HdotV);
    half norm = sqrt( ( AnisoRoughness.x + 1 ) * ( AnisoRoughness.y + 1 ) ) / ( 8 * UNITY_PI );
    half n0 = ( AnisoRoughness.x  *HdotX * HdotX + AnisoRoughness.y * HdotY * HdotY ) / ( 1 - NdotH * NdotH );
    half specular = norm * F * pow( max( NdotH , 0 ), n0 ) / ( HdotV * max( NdotV, NdotL  ));

	return diffuse + specular;
}

//---------------------------------------------------------------------------------
// Walter07, w/ GGX
half3 brdfWalter(half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y , half Roughness )
{
    half3 H = normalize(L+V);
    half NdotL = max( 0, dot(N, L));
    half NdotV = max( 0, dot(N, V));
    half NdotH = dot(N, H);
    half VdotH = dot(V, H);

    half D = D_GGX(Roughness, NdotH);
    half Vis = Vis_Smith(Roughness, NdotL, NdotV);
	half3 F =  F_CookTorrance( specColor, VdotH);

	return  D * Vis * F * (NdotL);
}

//---------------------------------------------------------------------------------
// Ward BRDF
// this is the formulation specified in "Notes on the Ward BRDF" - Bruce Walter, 2005
half3 brdfWard(half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y, half2 AnisoRoughness )
{
    half3 H = normalize(L + V);
	half NdotL = max(0, dot(N, L));
	half NdotV = saturate(dot(V, N));
	half NdotH = saturate(dot(H, N));
	
	half spec = D_WardAniso(AnisoRoughness.x, AnisoRoughness.y, NdotL, NdotV, NdotH, H, X, Y);
    return  specColor * spec * NdotL;
}

//---------------------------------------------------------------------------------

half3 brdfWardIsotropic(half3 n, half3 v, half3 l, half Roughness) 
{
	half3 h = normalize(l + v);

	half VdotN = dot(v, n);
	half LdotN = dot(l, n);
	half HdotN = dot(h, n);
	half r_sq = (Roughness * Roughness) + 1e-5;
	// (Adding a small bias to r_sq stops unexpected
	//  results caused by divide-by-zero)

	// Define material properties
	half3 Ps = half3(1.0, 1.0, 1.0);

	// Compute the specular term
	half exp_a = -pow(tan(acos(HdotN)), 2);
	half spec_num = exp(exp_a / r_sq);

	half spec_den = 4.0 * 3.14159 * r_sq;
	spec_den *= sqrt(LdotN * VdotN);

	half3 Specular = Ps * (spec_num / spec_den);

	return Specular * dot(n, l);

	//Simple !!
	//return specColor * exp ( - r_sq * (1.0f - HdotN) / HdotN );
}
//---------------------------------------------------------------------------------

// Edwards halfway-vector disk 2006
//<<The Halfway Vector Disk for Empirical BRDF Modeling>>
half lump(half3 H, half R, half N)
{
    return (N + 1)/(UNITY_PI*R*R) * pow(1 - dot(H, H)/(R*R), N);
}

half3 brdfEdwards(half3 specColor, half3 L, half3 V, half3 N, half3 X, half3 Y, half2 AnisoRoughness)
{
    half NdotV = max(0, dot(N,V));
    half NdotL = max(0, dot(N,L));

    half3 H = normalize(L + V);
    half NdotH = dot(N,H);
    half LdotH = dot(L,H);

    // scaling projection
    half3 uH = L+V; // unnormalized H
    half3 h = NdotV / dot(N,uH) * uH;
    half3 huv = h - NdotV * N;

    // specular term (D and G)
	//half k = 0.5;
    //half p1 = lump(huv, AnisoRoughness.x, X); 
	//half p2 = lump(huv, AnisoRoughness.y, Y);
	//half p = (1 - k) * p1 + k * p2;

	half p = lump(huv, AnisoRoughness.x, 10);

    return specColor * p * (NdotV * NdotV) / (4 * NdotL * LdotH * pow(NdotH, 3));
}

//---------------------------------------------------------------------------------

//Strauss
/*
 * http://content.gpwiki.org/D3DBook:(Lighting)_Strauss
 */

#define SQR(x) ((x) * (x))

half fresnel(half x) 
{
	const half kf = 1.12;

	half p = 1.0 / SQR(kf);
	half num = 1.0 / SQR(x - kf) - p;
	half denom = 1.0 / SQR(1.0 - kf) - p;

	return num / denom;
}

half shadow(half x) 
{
	const half ks = 1.01;

	half p = 1.0 / SQR(1.0 - ks);
	half num = p - 1.0 / SQR(x - ks);
	half denom = p - 1.0 / SQR(ks);

	return num / denom;
}

half3 brdfStrauss(half3 DiffuseColor, half3 n, half3 v, half3 l, half Roughness, half Metalness , half Transparency) 
{
	half Smoothness = 1 - Roughness;

	half3 h = reflect(l, n);

	// Declare any aliases:
	half NdotL = dot(n, l);
	half NdotV = dot(n, v);
	half HdotV = dot(h, v);
	half fNdotL = fresnel(NdotL);
	half s_cubed = Smoothness * Smoothness * Smoothness;

	// Evaluate the diffuse term
	half d = (1.0 - Metalness * Smoothness);
	half Rd = (1.0 - s_cubed) * (1.0 - Transparency);
	half3 diffuse = NdotL * d * Rd * DiffuseColor;

	// Compute the inputs into the specular term
	half r = (1.0 - Transparency) - Rd;

	half j = fNdotL * shadow(NdotL) * shadow(NdotV);

	// 'k' is used to provide small off-specular
	// peak for very rough surfaces. Can be changed
	// to suit desired results...
	const half k = 0.1;
	half reflect = min(1.0, r + j * (r + k));

	half3 C1 = half3(1.0, 1.0, 1.0);
	half3 Cs = C1 + Metalness * (1.0 - fNdotL) * (DiffuseColor - C1);

	// Evaluate the specular term
	half3 specular = Cs * reflect;
	specular *= pow(-HdotV, 3.0 / (1.0 - Smoothness));

	// Composite the final result, ensuring
	// the values are >= 0.0 yields better results. Some
	// combinations of inputs generate negative values which
	// looks wrong when rendered...
	diffuse = max(half3(0.0,0.0,0.0), diffuse);
	specular = max(half3(0.0,0.0,0.0), specular);
	return diffuse + specular;
}

#endif //__LIGHTING_MODEL_CGINC