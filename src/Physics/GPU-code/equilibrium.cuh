#pragma once
#include "hermite.cuh"

__device__ float c_sound(float T) {
	return csoi;
}


//confirmation
__device__ float Feq(float u, float v, float a, float b, float p, float rho, float T) {
	//compressibility 
	float C = 0.0f;
	float a0 = 1;
	float axx   =  (u * u + C);
	float ayx   =  (u * v );
	float ayy   =  (v * v + C);
	float axxy  =  (u * u * v + C * v);
	float ayyx  =  (u * v * v + C * u);
	float axxyy =  (u * u * v * v + C * C + C * (u * u + v * v));
	float Hx = a;
	float Hy = b;
	float Hxx = a * a - cs2;
	float Hxy = a * b;
	float Hyy = b * b - cs2;
	float Hxxy = a * a * b - cs2 * b;
	float Hyyx = b * b * a - cs2 * a;
	float Hxxyy = a * a * b * b - cs2 *(a * a + b * b) + cs2 * cs2;

	return rho * (
		a0 + (u * a + b * v) / (cs2) +
		(Hxx * axx + Hyy * ayy + Hxy * ayx) / (2.0f * cs2 * cs2) +
		(Hxxy * axxy + Hyyx * ayyx) / (6.0f * cs2 * cs2 * cs2) +
		(Hxxyy * axxyy) / (24.0f * cs2 * cs2 * cs2 * cs2)
	);

}

// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
__device__ float Feq(float u, float v, float ex, float ey, float p, float rho, float T, float* H, float* a) {
	//compressibility 
	return rho * (
		H[0] * a[0] +
		(H[1] * a[1] + H[2] * a[2]) * (3.0f) +
		(H[3] * a[3] + H[4] * a[4] + H[5] * a[5]) * (4.5f) +
		(H[6] * a[6] + H[7] * a[7]) * (4.5f) +
		(H[8] * a[8]) * (3.375f)
	);
}

__device__ float feq_func(float rho, float* H, float* a) {
	//compressibility 
	return rho * (
		H[0] * a[0] +
		(H[1] * a[1] + H[2] * a[2]) * (3.0f) +
		(H[3] * a[3] + H[4] * 2 * a[4] + H[5] * a[5]) * (4.5f) +
		(3 * H[6] * a[6] + 3 * H[7] * a[7]) * (4.5f) +
		(H[8] * a[8] * 6) * (3.375f)
		);
}
__device__ float feq_func(float rho, float* H, float* a, float vi) {
	//compressibility 
	float inv2 = 1 / (cs * cs);
	return rho * (
		1.0f +
		((float)H[1] * (float)a[1] + (float)H[2] * (float)a[2]) * (inv2) +
		((float)H[3] * (float)a[3] + (float)H[4] * 2 * (float)a[4] + (float)H[5] * (float)a[5]) * (inv2 * inv2 * 0.5f) +
		( 3 * (float)H[6] * (float)a[6] +  3 * (float)H[7] * (float)a[7]) * (1.0f / 6.0f * inv2 * inv2 * inv2) //+
		//(H[8] * a[8] * 6) * (inv2 * inv2 * inv2 * inv2) * 1.0f / 24.0f
		);
}

__device__ float feq_func3(float rho, int ex, int ey, float* a, float vi) {
	//compressibility 
	float inv2 = 1 / (cs * cs);
	return rho * (
		1.0f +
		(ex * a[1] + ey * a[2]) * (inv2)+
		((ex * ex - cs * cs) * a[3] + (ex * ey) * 2 * a[4] + (ey * ey - cs * cs) * a[5]) * (inv2 * inv2 * 0.5f) +
		(((ex * ex - cs * cs)* ey) * 3  * a[6] + 3 * (ex * (ey * ey - cs * cs)) * a[7]) * (0.16666666666666f * inv2 * inv2 * inv2) /*
		//(H[8] * a[8] * 6) * (inv2 * inv2 * inv2 * inv2) * 0.04166666666666666666666666666667f*/
		);
}

__device__ float feq_func0(float rho, float u, float v, int a, int b) {
	//compressibility 
	return rho * (
		  1.0f +
		  (a * u + v * b) * 3.0f +
		  ((a * u + v * b) * (a * u + v * b)) * 4.5f -
		  (u * u + v * v) * 0.5f * 3.0f
		);
}

//confirmation
__device__ float f_eq(float u, float v, int a, int b, float p, float rho, float C) {
	return rho * (
		1.0f +
		(a * u + b * v) / cs2 +
		(H_aa(a, a) * A_aa(u, u, C) + H_aa(b, b) * A_aa(v, v, C) + H_ab(a, b) * A_ab(u, v, C)) / (2 * cs2 * cs2) +
		(H_aaa(a) * A_aaa(u, u, C) + H_baa(b, a) * A_baa(u, v, C) + H_aaa(b) * A_aaa(v, v, C)) / (6 * cs2 * cs2 * cs2) +
		(H_bbaa(b, a) * A_bbaa(u, v, C)) / (24 * cs2 * cs2 * cs2 * cs2)
	);
}