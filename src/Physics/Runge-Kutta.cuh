#pragma once



#define psi0 0.0f

__device__ float entropy(float T, float rho) {
	return C_v * logf(T / powf(rho, k));
}

__device__ float temperature(float s, float rho) {
	return expf(s / C_v) * powf(rho, k);
}

__device__ float strain_rate(float dudx, float dudy, float dvdx, float dvdy) {
	return miu * (
		dudx * dudx * 2.0f + dvdy * dvdy * 2.0f +
		2.0f * dudy * dvdx + dudy * dudy + dvdx * dvdx
		- 2.0f / 3.0f * (dudx + dvdy) * (dudx + dvdy)
		);
}

__device__ float godunov_x(float RR, float R, float L, float LL, float phi, float u) {
	if (u > 0) {
		float xR = (R - phi) * 0.5f + phi;
		float yR = (phi - L) * 0.5f + L;
		return (xR - yR) * u;
	}
	else {
		//find phiR
		float r = (R - phi) / (RR - R + 1E-7f);
		float r1 = (phi - L) / (R - phi + 1E-7f);
		float psi1 = 2.0f * r / (1 + r * r);
		float psi2 = 2.0f * r1 / (1 + r1 * r1);
		float dphi_plus_one_half = RR - R;
		float dphi_minus_one_half = R - phi;
		float phi_R_plus = R - psi1 * 0.5f * (dphi_plus_one_half);
		float phi_R_minus = phi - psi2 * 0.5f * (dphi_minus_one_half);
		return (phi_R_plus - phi_R_minus) * u;
	}
}

#define klu 0.33333333f
__device__ float muscl(float RR, float R, float L, float LL, float phi, float u) {
	if (u > 0) {
		float r = (phi - L) / (R - phi + 1E-7f);
		float r1 = (L - LL) / (phi - L + 1E-7f);
		float psi1 = 2.0f * r / (1 + r * r);
		float psi2 = 2.0f * r1 / (1 + r1 * r1);
		float dphi_plus_one_half = R - phi;
		float dphi_minus_one_half = phi - L;
		float dphi_minus_three_half = L - LL;
		float phi_L_plus = phi + psi1 * 0.25f * ((1 - klu) * dphi_minus_one_half + (1 + klu) * dphi_plus_one_half);
		float phi_L_minus = L + psi2 * 0.25f *  ((1 - klu) * dphi_minus_three_half + (1 + klu) * dphi_minus_one_half);
		return (phi_L_plus - phi_L_minus) * u / del_x;
	}
	else {
		float r = (R - phi) / (RR - R + 1E-7f);
		float r1 = (phi - L) / (R - phi + 1E-7f);
		float psi1 = 2.0f * r / (1 + r * r);
		float psi2 = 2.0f * r1 / (1 + r1 * r1);
		float dphi_plus_one_half = R - phi;
		float dphi_plus_three_half = RR - phi;
		float dphi_minus_one_half = phi - L;
		float dphi_minus_three_half = L - LL;
		float phi_R_plus = R - psi1 * 0.25f * ((1 - klu) * dphi_plus_three_half + (1 + klu) * dphi_plus_one_half);
		float phi_R_minus = phi - psi2 * 0.25f * ((1 - klu) * dphi_plus_one_half + (1 + klu) * dphi_minus_one_half);
		return (phi_R_plus - phi_R_minus) * u / del_x;
	}
}

__device__ float MUSCLX(float* phi, uint idx, uint idy, uint index, float u) {
	return muscl(phi[index + 2], phi[index + 1], phi[index - 1], phi[index - 2], phi[index], u);
}
__device__ float MUSCLY(float* phi, uint idx, uint idy, uint index, float u) {
	return muscl(phi[index + 2 * NX], phi[index + NX], phi[index - NX], phi[index - 2 * NX], phi[index], u);
}
__device__ float MUSCLX_BC(float* phi, uint idx, uint idy, uint index, float u) {
	if (idx == 1) {
		return muscl(phi[index + 2], phi[index + 1], phi[index - 1], phi[index - 1], phi[index], u);
	}
	if (idx == 0) {
		return muscl(phi[index + 2], phi[index + 1], phi[index], phi[index], phi[index], u);
	}
	if (idx == NX - 1) {
		return muscl(phi[index], phi[index], phi[index - 1], phi[index - 2], phi[index], u);
	}
	if (idx == NX - 2) {
		return muscl(phi[index], phi[index + 1], phi[index - 1], phi[index - 2], phi[index], u);
	}
	return muscl(phi[index + 2], phi[index + 1], phi[index - 1], phi[index - 2], phi[index], u);
}

__device__ float MUSCLY_BC(float* phi, uint idx, uint idy, uint index, float u) {
	if (idy == 1) {
		return muscl(phi[index + 2 * NX], phi[index + NX], phi[index - NX], phi[index - NX], phi[index], u);
	}
	if (idy == 0) {
		return muscl(phi[index + 2 * NX], phi[index + NX], phi[index], phi[index], phi[index], u);
	}
	if (idy == NY - 1) {
		return muscl(phi[index], phi[index], phi[index - NX], phi[index - 2 * NX], phi[index], u);
	}
	if (idy == NY - 2) {
		return muscl(phi[index], phi[index + NX], phi[index - NX], phi[index - 2 * NX], phi[index], u);
	}
	return muscl(phi[index + 2 * NX], phi[index + NX], phi[index - NX], phi[index - 2 * NX], phi[index], u);
}





//classical scheme
__device__ float laplacian(float* phi, uint index) {
	return (phi[index + 1] + phi[index - 1] + phi[index + NX] + phi[index - NX] - 4.0f * phi[index]) / (del_x * del_x);
}
__device__ float laplacian_BC(float* phi, uint index, uint idx, uint idy) {
	float value = 0.0f;
	bool recalcX = true;
	bool recalcY = true;
	if (idx == 0) {
		recalcX = false;
		value += phi[index + 1] + phi[index];
	}
	if (idx == NX - 1) {
		recalcX = false;
		value += phi[index - 1] + phi[index];
	}
	if (idy ==  NY - 1) {
		recalcY = false;
		value += phi[index - NX] + phi[index];
	}
	if (idy == 0) {
		recalcY = false;
		value += phi[index + NX] + phi[index];
	}
	if (recalcX) {
		value += phi[index + 1] + phi[index - 1];
	}
	if (recalcY) {
		value += phi[index + NX] + phi[index - NX];
	}
	return (value - 4.0f * phi[index]) / (del_x * del_x);
}


//stress tensor
// stress = miu * (
// grad u + grad u T - 2/ 3 div u I)
// then strain rate:
// grad u : grad u + grad u T : grad u - 2/3 div u I : grad u
// gradu dot grad u + grad u T dot grad u T
//
// 2d case yields -> du/dx ^2 + du/dy ^2 + dv/dx ^2 + dv/dy ^2 
// du/dx ^2 + 2 * dv/dx * du/dy +  dv/dy ^2
// -2/3 * (du/dx + dv/dy) * (du/dx + dv/dy)



__global__ void sPDE(Domain* d, int n) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	bool bc = (idx < 2 || idy < 2  || idx > NX - 2 || idy > NY - 2);
	//if (idx > NX - 1 || idy > NY - 1)return;
	uint index = idx + idy * NX;
	float a, b, nabla_t;
	float sr;
	vec2 uloc = d->u[index];
	if (!bc) {
		a =  MUSCLX(d->s, idx, idy, index, uloc.x * vl);
		b =  MUSCLY(d->s, idx, idy, index, uloc.y * vl);// MUSCLY(s, idx, idy, index, 0.0f);
		nabla_t = lambda_T * laplacian(d->T, index);
		//Stress tensor(d->u, index, idx, idy, bc);
		//sr = 100*strain_rate(tensor.dudx, tensor.dudy, tensor.dvdx, tensor.dvdy);
		//nabla_t += sr;
	}
	else {
		a =  MUSCLX_BC(d->s, idx, idy, index, uloc.x * vl);
		b =  MUSCLY_BC(d->s, idx, idy, index, uloc.y * vl);
		//Stress tensor(d->u, index, idx, idy, bc);
		//sr = 100 * strain_rate(tensor.dudx, tensor.dudy, tensor.dvdx, tensor.dvdy);
		//nabla_t += sr;
		nabla_t = lambda_T * laplacian_BC(d->T, index, idx, idy);// laplacian_BC(T, index, idx, idy);
	}
	float density = d->rho[index] / rhol;
	nabla_t /= (density * d->T[index]);
	
	//no runge kutta just yet
	d->T_buffer[index] = d->s[index] -(a + b - nabla_t) * del_t;
}



__global__ void getT(Domain* d,  float* output) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	//swap buffers
	d->s[index] = d->T_buffer[index];
	//
	float density = d->rho[index] / rhol;
	float T_local = temperature(d->s[index], density);
	d->T[index] = T_local;
	d->p[index] = ((d->rho[index] * T_local * 0.1f) * 0.238095f);
}



