#pragma once

__global__ void compute_macros(Domain* d,  int ctrl) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
	bool bc = idx < 1 || idy < 1 || idx >= NX - 1 || idy >= NY - 1;
	bool bc1 = idx < 2 || idy < 2 || idx >= NX - 2 || idy >= NY - 2;
	float parx, pary;
	vec2 u = { 0,0 };
	vec2 e[9] = { { 0,  0}, { C0,  0}, { 0,  C0}, {-C0,  0}, { 0, -C0}, { C0,  C0}, {-C0,  C0}, {-C0, -C0}, { C0, -C0}, };
	float density = 0.0f;
	for (int i = 0; i < 9; i++) {
		density += d->f[i][index];
		u.x += (d->f[i][index] * e[i].x);
		u.y += (d->f[i][index] * e[i].y);
	}
	if (density < 0.0001f) {
		u.x = 0.0f;
		u.y = 0.0f;
	}
	else {
		u.x /= density;
		u.y /= density;
	}
	//we store lattice values
	d->u[index] = u;
	d->rho[index] = density;;
}