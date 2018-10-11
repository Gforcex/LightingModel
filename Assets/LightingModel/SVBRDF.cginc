
#include "Math.cginc"
//Ref: eth-BRDF-Shader

// inspiration: https://github.com/ashima/webgl-noise
float3 c1 = float3(183.0 / 255.0, 65.0 / 255.0, 14.0 / 255.0);
float3 c2 = float3(165.0 / 255.0, 93.0 / 255.0, 53.0 / 255.0);
float3 c3 = float3(128.0 / 255.0, 44.0 / 255.0, 8.0 / 255.0);

float3 mod289(float3 x) {
	return x - floor(x * (1. / 289.)) * 289.;
}
float4 mod289(float4 x) {
	return x - floor(x * (1. / 289.)) * 289.;
}
float4 permute(float4 x) {
	return mod289(((x*34.) + 1.)*x);
}
float4 taylorInvSqrt(float4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}
float3 fade(float3 t) {
	return t * t*t*(t*(t*6. - 15.) + 10.);
}

float cnoise(float3 P) {
	float3 Pi0 = floor(P); // Integer part for indexing
	float3 Pi1 = Pi0 + float3(1.); // Integer part + 1
	Pi0 = mod289(Pi0);
	Pi1 = mod289(Pi1);
	float3 Pf0 = fract(P); // Fractional part for interpolation
	float3 Pf1 = Pf0 - float3(1.); // Fractional part - 1.0
	float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
	float4 iy = float4(Pi0.yy, Pi1.yy);
	float4 iz0 = Pi0.zzzz;
	float4 iz1 = Pi1.zzzz;

	float4 ixy = permute(permute(ix) + iy);
	float4 ixy0 = permute(ixy + iz0);
	float4 ixy1 = permute(ixy + iz1);

	float4 gx0 = ixy0 * (1. / 7.);
	float4 gy0 = fract(floor(gx0) * (1. / 7.)) - 0.5;
	gx0 = fract(gx0);
	float4 gz0 = float4(0.5) - abs(gx0) - abs(gy0);
	float4 sz0 = step(gz0, float4(0.0));
	gx0 -= sz0 * (step(0.0, gx0) - 0.5);
	gy0 -= sz0 * (step(0.0, gy0) - 0.5);

	float4 gx1 = ixy1 * (1. / 7.);
	float4 gy1 = fract(floor(gx1) * (1. / 7.)) - 0.5;
	gx1 = fract(gx1);
	float4 gz1 = float4(0.5) - abs(gx1) - abs(gy1);
	float4 sz1 = step(gz1, float4(0.0));
	gx1 -= sz1 * (step(0.0, gx1) - 0.5);
	gy1 -= sz1 * (step(0.0, gy1) - 0.5);

	float3 g000 = float3(gx0.x, gy0.x, gz0.x);
	float3 g100 = float3(gx0.y, gy0.y, gz0.y);
	float3 g010 = float3(gx0.z, gy0.z, gz0.z);
	float3 g110 = float3(gx0.w, gy0.w, gz0.w);
	float3 g001 = float3(gx1.x, gy1.x, gz1.x);
	float3 g101 = float3(gx1.y, gy1.y, gz1.y);
	float3 g011 = float3(gx1.z, gy1.z, gz1.z);
	float3 g111 = float3(gx1.w, gy1.w, gz1.w);

	float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
	g000 *= norm0.x;
	g010 *= norm0.y;
	g100 *= norm0.z;
	g110 *= norm0.w;
	float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
	g001 *= norm1.x;
	g011 *= norm1.y;
	g101 *= norm1.z;
	g111 *= norm1.w;

	float n000 = dot(g000, Pf0);
	float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
	float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
	float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
	float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
	float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
	float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
	float n111 = dot(g111, Pf1);

	float3 fade_xyz = fade(Pf0);
	float4 n_z = lerp(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
	float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
	float n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x);
	return 2.2 * n_xyz;
}

//-------------------------------------------------------------------------------------------

//diffColor = diffColor * getColor
//specColor = specColor * getColor
float3 getColor(float3 vTC) {
	float scale = .5;
	float shift = 1000.0;
	float x = scale * vTC.x + shift + 10.0;
	float y = scale * vTC.y + shift - 100000.0;
	float z = scale * vTC.z + shift + 0.0;


	float frequency = .5;
	float amplitude = 46.2;
	float c = 0.;
	for (float i = 0.; i < 10.; i++) {
		float p = cnoise(frequency * float3(x, y, z));
		c += amplitude * p;
		c += sin(abs(x + y + z + p) + cos(y + p));
		amplitude *= 0.2;
		frequency *= 2. + i * 8.;
	}

	c = sin(c / 20.0) + cos(c / 20.0);

	if (c < 0.)
		return c3;
	else if (c < 0.95)
		return lerp(c1, c2, c);
	else if (c < 0.97)
		return lerp(c2, c1, c);
	else
		return lerp(c3, c2, c);
}