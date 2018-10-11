/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

//-----------------------------------------------------------------------------
// Diffuse BRDF - diffuseColor is expected to be multiply by the caller
//-----------------------------------------------------------------------------

float3 Diffuse_Lambert(float3 DiffuseColor)
{
	return DiffuseColor * (1 / PI);
}

// ------------------------------------------------------------
// Ref: Diffuse Lighting for GGX + Smith Microsurfaces, p. 113.
float3 Diffuse_GGX(float3 DiffuseColor, float NdotV, float NdotL, float NdotH, float LdotV, float perceptualRoughness)
{
	float facing = 0.5 + 0.5 * LdotV;
	float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NdotH) / NdotH);
	float transmitL = 1 - F_Schlick(0, NdotL);
	float transmitV = 1 - F_Schlick(0, NdotV);
	float smooth = transmitL * transmitV * 1.05;             // Normalize F_t over the hemisphere
	float single = lerp(smooth, rough, perceptualRoughness); // Rescaled by PI
															 // This constant is picked s.t. setting perceptualRoughness, DiffuseColor and all angles to 1
															 // allows us to match the Lambertian and the Disney Diffuse models. Original value: 0.1159.
	float multiple = perceptualRoughness * (0.079577 * PI);  // Rescaled by PI

	return INV_PI * (single + DiffuseColor * multiple);
}
// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5(1 - NoV);
	float FdL = 1 + (FD90 - 1) * Pow5(1 - NoL);
	return DiffuseColor * ((1 / PI) * FdV * FdL);
}

// ------------------------------------------------------------
//粗糙的表面： 布料 陶瓷 沙地等
// [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
float3 Diffuse_OrenNayar(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float a = Roughness * Roughness;
	float s = a;// / ( 1.29 + 0.5 * a );
	float s2 = s * s;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
	float C1 = 1 - 0.5 * s2 / (s2 + 0.33);
	float C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * (Cosri >= 0 ? rcp(max(NoL, NoV)) : 1);
	return DiffuseColor / PI * (C1 + C2) * (1 + Roughness * 0.5);
}

//Ref: blender-shader
float3 Diffuse_OrenNayar(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH, float LoV)
{
	float div = 1.0 / (PI + ((3.0 * PI - 4.0) / 6.0) * Roughness);

	float A = 1.0 * div;
	float B = Roughness * div;

	float s = LoV - NoL * NoV;
	float t = lerp(1.0, max(NoL, NoV), step(0.0, s));

	return DiffuseColor * (A + B * s / t) * NoL;
}

half3 Diffuse_OrenNayarSimple(float3 DiffuseColor, half Roughness, half3 N, half3 V, half3 L)
{
	float VdotN = dot(V, N);
	float LdotN = dot(L, N);
	float alpha = max(acos(VdotN), acos(LdotN));
	float beta = min(acos(VdotN), acos(LdotN));
	float gamma = dot(V - N * VdotN, L - N * LdotN);
	float sigma2 = Roughness * Roughness;

	float A = 1.0 - 0.5 * (sigma2 / (sigma2 + 0.33));
	float B = 0.45 * (sigma2 / (sigma2 + 0.09));
	float C = sin(alpha) * tan(beta);

	return DiffuseColor * max(0.0, dot(N, L)) * (A + B * max(0.0, gamma) * C);
}

float3 Diffuse_OrenNayarComplex(float3 DiffuseColor, half Roughness, float3 N, float3 V, float3 L)
{
	float VdotN = dot(V, N);
	float LdotN = dot(L, N);
	float alpha = max(acos(VdotN), acos(LdotN));
	float beta = min(acos(VdotN), acos(LdotN));
	float gamma = dot(normalize(V - N * VdotN), normalize(L - N * LdotN)); 
	float sigma2 = Roughness * Roughness;
	//float sigma2 = pow(Roughness * UNITY_PI / 180, 2); //Disney brdf expoler

	float C1 = 1.0 - 0.5 * (sigma2 / (sigma2 + 0.33));

	float C2 = 0.45 * (sigma2 / (sigma2 + 0.09));
	if (gamma >= 0) C2 *= sin(alpha);
	else C2 *= (sin(alpha) - pow((2 * beta) / PI, 3));

	float C3 = (1.0 / 8.0);
	C3 *= (sigma2 / (sigma2 + 0.09));
	C3 *= pow((4.0 * alpha * beta) / (PI * PI), 2);

	float A = gamma * C2 * tan(beta);
	float B = (1 - abs(gamma)) * C3 * tan((alpha + beta) / 2.0);

	return DiffuseColor * max(0.0, dot(N, L)) * (C1 + A + B);

	//Disney's BRDF explorer
	//rho --- DiffuseColor
	//float L1 = rho / UNITY_PI * (C1 + gamma * C2 * tan(beta) + (1 - abs(gamma)) * C3 * tan((alpha + beta) / 2));
	//float L2 = 0.17 * rho*rho / UNITY_PI * sigma2 / (sigma2 + 0.13) * (1 - gamma * (4 * beta*beta) / (UNITY_PI*UNITY_PI));
	//
	//return L1 + L2;
}

// ------------------------------------------------------------
//丝绒
float3 Diffuse_Minnaert(float3 L, float3 V, float3 N, float k)
{
	float3 H = normalize(L + V);
	return ((k + 1) * pow(dot(N, L)*dot(N, V), k - 1) / (2 * UNITY_PI));
}

// ------------------------------------------------------------
// [Gotanda 2014, "Designing Reflectance Models for New Consoles"]
float3 Diffuse_Gotanda(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float F0 = 0.04;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
#if 1
	float a2_13 = a2 + 1.36053;
	float Fr = (1 - (0.542026*a2 + 0.303573*a) / a2_13) * (1 - pow(1 - NoV, 5 - 4 * a2) / a2_13) * ((-0.733996*a2*a + 1.50912*a2 - 1.16402*a) * pow(1 - NoV, 1 + rcp(39 * a2*a2 + 1)) + 1);
	//float Fr = ( 1 - 0.36 * a ) * ( 1 - pow( 1 - NoV, 5 - 4*a2 ) / a2_13 ) * ( -2.5 * Roughness * ( 1 - NoV ) + 1 );
	float Lm = (max(1 - 2 * a, 0) * (1 - Pow5(1 - NoL)) + min(2 * a, 1)) * (1 - 0.5*a * (NoL - 1)) * NoL;
	float Vd = (a2 / ((a2 + 0.09) * (1.31072 + 0.995584 * NoV))) * (1 - pow(1 - NoL, (1 - 0.3726732 * NoV * NoV) / (0.188566 + 0.38841 * NoV)));
	float Bp = Cosri < 0 ? 1.4 * NoV * NoL * Cosri : Cosri;
	float Lr = (21.0 / 20.0) * (1 - F0) * (Fr * Lm + Vd + Bp);
	return DiffuseColor / PI * Lr;
#else
	float a2_13 = a2 + 1.36053;
	float Fr = (1 - (0.542026*a2 + 0.303573*a) / a2_13) * (1 - pow(1 - NoV, 5 - 4 * a2) / a2_13) * ((-0.733996*a2*a + 1.50912*a2 - 1.16402*a) * pow(1 - NoV, 1 + rcp(39 * a2*a2 + 1)) + 1);
	float Lm = (max(1 - 2 * a, 0) * (1 - Pow5(1 - NoL)) + min(2 * a, 1)) * (1 - 0.5*a + 0.5*a * NoL);
	float Vd = (a2 / ((a2 + 0.09) * (1.31072 + 0.995584 * NoV))) * (1 - pow(1 - NoL, (1 - 0.3726732 * NoV * NoV) / (0.188566 + 0.38841 * NoV)));
	float Bp = Cosri < 0 ? 1.4 * NoV * Cosri : Cosri / max(NoL, 1e-8);
	float Lr = (21.0 / 20.0) * (1 - F0) * (Fr * Lm + Vd + Bp);
	return DiffuseColor / PI * Lr;
#endif
}

// ------------------------------------------------------------
half clampLight(half specular, half falloff, half lightAngle)
{
	return specular * smoothstep(0.0, falloff * 0.5 * UNITY_PI, 0.5 * UNITY_PI - lightAngle);
}
