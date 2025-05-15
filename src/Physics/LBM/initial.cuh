#pragma once
//vortex
__device__ float rho_vortex(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return  powf(1.0f - (k) / (8 * gamma * 3.141f * 3.141f) * .25f * expf(1 - r * r), 1.0f / k);
}

__device__ float us(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return  -0.0f - 0.25 / (3.141) * expf(0.5f * (1 - r * r)) * (idy - NY / 2) * del_x;
}

__device__ float vs(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return -0.0f + 0.25 / (3.141) * expf(0.5f * (1 - r * r)) * (idx - NY / 2) * del_y;
}
//__________________________________________________________________________Gaussian Pulse Isothermal_____________________________________________________________________________//

__device__ float rho_acoustic(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return  1.0f + 0.01f * expf(-.1732867951f * r * r);
}
__device__ float p_acoustic(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return  1.0f + 0.01f * expf(-.1732867951f * r * r);
}
//__________________________________________________________________________Gaussian Pulse_____________________________________________________________________________//
__device__ float rho_acousticThermal(int idx, int idy) {
	return  1.0f;
}
__device__ float p_acousticThermal(int idx, int idy) {
	float r = sqrtf((idx - NX / 2) * del_x * (idx - NX / 2) * del_x + (idy - NY / 2) * del_y * (idy - NY / 2) * del_y);
	return  1.0f + expf(-1 * r * r);
}