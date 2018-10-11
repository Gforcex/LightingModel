#ifndef __MATH_CGINC__
#define __MATH_CGINC__

#define HALF_MAX        65504.0
#define EPSILON         1.0e-4
#define PI              3.14159265359
#define TWO_PI          6.28318530718
#define FOUR_PI         12.56637061436
#define INV_PI          0.31830988618
#define INV_TWO_PI      0.15915494309
#define INV_FOUR_PI     0.07957747155
#define HALF_PI         1.57079632679
#define INV_HALF_PI     0.636619772367

inline half Pow5 (half x)
{
	return x*x * x*x * x;
}

inline half Square(half x)
{
	return x * x;
}

half rcp(half v)
{
	return 1.0h/v;
}

float rcpf(float v)
{
	return 1.0f/v;
}

// Generalized Power Function
half fastPow(half x, half n)
{
    return exp(log(x) * n);
}

// Spherical Gaussian Power Function 
half GaussianPow(half x, half n)
{
    n = n * 1.4427f + 1.4427f; // 1.4427f --> 1/ln(2)
    return exp2(x * n - n);
}

//
half ApproxPow(half x, half n)
{
	return exp2(x * n - n);
}

half Remap(half value, half oldMin, half oldMax, half newMin, half newMax)
{
	return (newMin + ( value - oldMin) * (newMax - newMin) / (oldMax - oldMin));
}


#endif //__MATH_CGINC__