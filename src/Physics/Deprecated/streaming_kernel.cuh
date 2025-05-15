#pragma once
#include "../GPU-code/hermite.cuh"

__global__ void test(Domain* d) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	d->f[index] = d->fbuffer[index];
}
//
//__global__ void compressible_collide(Domain* d, float** fmain, float** fbuffer) {
//	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
//	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
//	uint index = idx + idy * NX;
//	uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
//	bool bc = idx < 1 || idy < 1 || idx >= NX - 1 || idy >= NY - 1;
//	bool bc1 = idx < 2 || idy < 2 || idx >= NX - 2 || idy >= NY - 2;
//	vec2 e[9] = { { 0,  0}, { C0,  0}, { 0,  C0}, {-C0,  0}, { 0, -C0}, { C0,  C0}, {-C0,  C0}, {-C0, -C0}, { C0, -C0}, };
//	float w[9] = { (float)4 / 9,(float)1 / 9, (float)1 / 9, (float)1 / 9, (float)1 / 9,(float)1 / 36, (float)1 / 36, (float)1 / 36, (float)1 / 36 };
//	//interior points;
//	
//	__shared__ float h[9][11];
//	//// {H0, Hx, Hy, Hxx, Hxy, Hyy, Hxxx, Hxyy, Hyyx, Hyyy, Hxxyy}
//	//if (threadIdx.x < 11 && threadIdx.y < 9) {
//	//	h[threadIdx.y][threadIdx.x] = d->hermite[threadIdx.y][threadIdx.x];
//	//}
//	//__syncthreads();
//	//compute correcting factor:
//	vec2 u = d->u[index];
//	//if (bc)return;
//	if (d->mask[index]) {
//		//if (_is_interior(mask, index))return;
//	}
//
//	float relaxation = 10E-5 / d->p[index];
//	if (!bc) {
//		float ex = abs((d->p[index - 1] + d->p[index + 1] - 2 * d->p[index]) / (d->p[index - 1] + d->p[index + 1] + 2 * d->p[index]));
//		float ey = abs((d->p[index - NX] + d->p[index + NX] - 2 * d->p[index]) / (d->p[index - NX] + d->p[index + NX] + 2 * d->p[index]));
//		relaxation = tau_ + ((ex > ey ? ex : ey) * del_t + relaxation) / del_t;
//	}
//	else {
//		relaxation = tau_ ;
//	}
//	//first order upwind scheme
//	float csoi0 = csoi;
//	//Correction corr = correction(d->rho, d->p, d->u, u, idx, idy, index, csoi0, bc);
//
//	float c2 = 1.0f / (csoi0 * csoi0);
//	//computation of feq and psi
//	float fneq[9];
//	float psi[9];
//	float feq[9];
//	float f[9];
//	float Axx = 0.0f;
//	float Ayy = 0.0f;
//	float Axy = 0.0f;
//	//step 1 -> psi, feq, fneq
//
//	//now convert u to lattice values:
//	for (int i = 0; i < 9; i++) {
//		psi[i] = (h[i][3] * corr.parx + h[i][5] * corr.pary) * w[i] * 0.5f * c2 * c2;
//		//psi[i] = 0.0f;
//		d->correction[i][index] = psi[i];
//		feq[i] = w[i] * Feq(u.x, u.y, e[i].x, e[i].y, d->p[index], d->rho[index], csoi0);
//		f[i] = fmain[i][index];
//		//fneq
//		fneq[i] = f[i] - feq[i] + 0.5f * psi[i] * del_t;
//		//A
//		Axx += e[i].x * e[i].x  * fneq[i];
//		Ayy += e[i].y * e[i].y  * fneq[i];
//		Axy += e[i].x * e[i].y  * fneq[i];
//	}
//
//	//compute regularized A terms:
//	float AxxH, AyyH, AxyH;
//	Stress tensor(d->u, index, idx, idy, bc);
//	//compute recursive terms
//	AxxH = -1.0f * (tensor.dudx * 2 - k * (tensor.dudx + tensor.dvdy)) * relaxation * d->p[index] * del_t;
//	AxyH = -1.0f * (tensor.dvdx + tensor.dudy) * relaxation * d->p[index] * del_t;
//	AyyH = -1.0f * (tensor.dvdy * 2 - k * (tensor.dudx + tensor.dvdy)) * relaxation * d->p[index] * del_t;
//	//now compute proper terms
//	Axx = Axx * sigma + (1 - sigma) * AxxH;
//	Axy = Axy * sigma + (1 - sigma) * AxyH;
//	Ayy = Ayy * sigma + (1 - sigma) * AyyH;
//
//
//	float Axxx = 3.0f * Axx * u.x;
//	float Ayyy = 3.0f * Ayy * u.y;
//	float Axyy = Ayy * u.x + 2.0f * Axy * u.y;
//	float Ayxx = Axx * u.y + 2.0f * Axy * u.x;
//
//	//shock capture
//
//	for (int i = 0; i < 9; i++) {
//	// {H0, Hx, Hy, Hxx, Hxy, Hyy, Hxxx, Hxyy, Hyyx, Hyyy, Hxxyy}
//		float second_term = 0.5f * c2 * c2 * (
//			h[i][3] * (Axx)+
//			h[i][5] * (Ayy)+
//			h[i][4] * (Axy)
//			);
//		float third_term = 0.166666f * c2 * c2 * c2 * (
//			h[i][8]  * (Ayxx)+
//			h[i][7]  * (Axyy)+
//			h[i][9]  * (Ayyy)+
//			h[i][6]  * (Axxx)
//		);
//		fneq[i] = (second_term + third_term) * w[i];
//		f[i] = fneq[i] * (1.0f - del_t / relaxation)  + feq[i] + 0.5f * del_t * psi[i];
//	}
//	//streaming step:
//	if (d->mask[index]) {
//		float tmp[4];
//		tmp[0] = f[1]; f[1] = f[3]; f[3] = tmp[0];
//		tmp[1] = f[2]; f[2] = f[4]; f[4] = tmp[1];
//		tmp[2] = f[5]; f[5] = f[7]; f[7] = tmp[2];
//		tmp[3] = f[8]; f[8] = f[6]; f[6] = tmp[3];
//	}
//	for (int i = 0; i < 9; i++) {
//		int write_x = idx + e[i].x;
//		int write_y = idy + e[i].y;
//		//handle boundary
//		if (write_x == -1) {
//			write_x = NX - 1;
//		}
//		if (write_y == -1) {
//			write_y = (NY - 1);
//		}
//		if (write_x == NX) {
//			write_x = 0;
//		}
//		if (write_y == NY) {
//			write_y = 0;
//		}
//		fbuffer[i][(write_x + write_y * NX)] = f[i];
//	}
//}



