#pragma once

struct Correction {
	float parx, pary;
};

__device__ float correction_factor(float rho, float theta, float v, float csoi0) {
	return rho * v * (  - v * v);
}
__device__ float correction_factor(float rho, float theta, float v) {
	return rho * v * ( - v * v);
}
__device__ float correction_factor(float* rho, float* theta, float* v) {
	return (*rho) * (*v) * (1.0f - (*theta) - (*v) * (*v));
}


// rho, theta
__device__ float correction_factorX(float* rho, float* theta, vec2* u, float csoi0) {
	float par = (	
		correction_factor(rho[2], theta[2], u[2].x, csoi0) - correction_factor(rho[1], theta[1], u[1].x, csoi0)	
		);
	return par;// / (2 * del_x);
}

__device__ float correction_factorY(float* rho, float* theta, vec2* u, float csoi0) {
	float par = (
		correction_factor(rho[4], theta[4], u[4].y, csoi0) - correction_factor(rho[3], theta[3], u[3].y, csoi0)
	);
	return par;// / (2 * del_y);
}

//direct from global to aleviate registers

__device__ Correction correction(float* P, vec2* u) {
	Correction corr;
	corr.parx = correction_factorX(P + 5, P + 10, u, csoi);
	corr.pary = correction_factorY(P + 5, P + 10, u, csoi);
	return corr;
}

