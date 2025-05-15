#pragma once

__device__ bool _is_interior(bool* mask, uint index) {
	return mask[index + 1] && mask[index - 1] && mask[index + NX] && mask[index - NX] && mask[index + 1 + NX] && mask[index + 1 - NX] && mask[index - 1 + NX] && mask[index - 1 - NX];
}

__device__ uint extrap_index(bool* mask, uint index, uint idx, uint idy) {
	bool x0, x1, x2, y0, y1, y2, y3, z1, z2;
	x0 = mask[index - 1 - NX];
	x1 = mask[index - 1];
	x2 = mask[index - 1 + NX];
	y0 = mask[index + 1 - NX];
	y1 = mask[index + 1 ];
	y2 = mask[index + 1 + NX];
	z1 = mask[index + NX];
	z2 = mask[index - NX];
	//corners
	//if (!z1 && !y1 && !x1) return index + NX;
	//if (!z2 && !y1 && !x1) return index - NX;
	//if (!x1 && !z1 && !z1) return index - 1;
	//if (!y1 && !z2 && !z1) return index + 1;

	/*if (!x0) return index - 1 - NX;
	if (!x2) return index - 1 + NX;
	if (!y0) return index + 1 - NX;
	if (!y2) return index + 1 + NX;*/
	
	if (!x1 && !x0 && !x2 && y1 && y2 && y0 && z1 && z2) return index - 1;

	if (x1 && x0 && x2 && !y1 && !y2 && !y0 && z1 && z2) return index + 1;
	if (x1 && !x0 && x2 && y1 && y2 && !y0 && z1 && !z2) return index - NX;
	if (x1 && x0 && !x2 && y1 && !y2 && y0 && !z1 && z2) return index + NX;

	if (!x1 && !x0 && x2 && y1 && y2 && y0 && z1 && !z2) return index - 1 - NX;
	if (!x1 && x0 && !x2 && y1 && y2 && y0 && !z1 && z2) return index - 1 + NX;
	if (x1 && x0 && x2 && !y1 && y2 && !y0 && z1 && !z2) return index + 1 - NX;
	if (x1 && x0 && x2 && !y1 && !y2 && y0 && !z1 && z2) return index + 1 + NX;
	
	if (x1 && !x0 && x2 && y1 && y2 && y0 && z1 && z2) return index - 1 - NX;
	if (x1 && x0 && !x2 && y1 && y2 && y0 && z1 && z2) return index - 1 + NX;
	if (x1 && x0 && x2 && y1 && y2 && !y0 && z1 && z2) return index + 1-  NX;
	if (x1 && x0 && x2 && y1 && !y2 && y0 && z1 && z2) return index + 1 + NX;

	// outer sides
	if (!x1 && x0 && x2 && y1 && y2 && y0 && z1 && z2) return index - 1;
	if (x1 && x0 && x2 && !y1 && y2 && y0 && z1 && z2) return index + 1;
	if (x1 && x0 && x2 && y1 && y2 && y0 && !z1 && z2) return index + NX;
	if (x1 && x0 && x2 && y1 && y2 && y0 && z1 && !z2) return index - NX;
	return index;
}



__global__ void initialize_macro(Domain* d) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	float density = 1.0 ;
	d->rho[index] = rho_acoustic(idx, idy) * 1.0f;
	d->p[index] = rho_acoustic(idx, idy) * 1.0f * cs * cs;
	d->T[index] =  1.0f; //take R = .1
	d->u[index].x = .7f * cs;// .84f * us(idx, idy) * cs + .42f * cs;// 0.06648f;
	d->u[index].y = .0f * cs;// .84f * vs(idx, idy) * cs + 0.0f;
	d->s[index] = 1.0f;// entropy(d->T[index], d->rho[index] / 1.0); //entropy is constant so
}

	__global__ void compute_micro(Domain* d, float** ff, float ** fs) {
		uint idx = threadIdx.x + blockDim.x * blockIdx.x;
		uint idy = threadIdx.y + blockDim.y * blockIdx.y;
		uint index = idx + idy * NX;
		uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
		uint W =  idx == 0 ?  NX - 1 + idy * NX : index - 1;
		uint E =  idx == NX - 1 ? idy : index + 1;
		uint N =  idy == NY - 1 ? idx : index + NX;
		uint S =  idy == 0 ? idx + NX * (NY - 1) : index - NX;

		// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
		__shared__ float H[9][9];
		vec2INT es[9] = {
		{ 0,  0},
		{ 1,  0},
		{ 0,  1},
		{-1,  0},
		{ 0, -1},
		{ 1,  1},
		{-1,  1},
		{-1, -1},
		{ 1, -1},
		};
		//latice constants
		__shared__ vec2 e[9];
		__shared__ float w[9];

		if (threadIdx.x < 9 && threadIdx.y == 0) {
			for (int i = 0; i < 9; i++) {
				H[threadIdx.x][i] = d->hermite[threadIdx.x][i];
			}	
		}
		if (threadIdx.x < 9 && threadIdx.y == 0) {
			e[threadIdx.x].x = d->e[threadIdx.x].x;
			e[threadIdx.x].y = d->e[threadIdx.x].y;
			w[threadIdx.x] = d->w[threadIdx.x];
		}
		__syncthreads();


		 //{0, -x, + x, -y, + y}
		vec2 u;
		float P[15];
		float feq[9], a[9], aeq[11], psi[9];

		//read the GLOBAL field variables to registers (harsh on registers)
		u = d->u[index];
		float div = 1.0f / (cs * cs);
		float dudx = (d->u[E].x - d->u[W].x) / (2);
		float dudy = (d->u[N].x - d->u[S].x) / (2);
		float dvdx = (d->u[E].y - d->u[W].y) / (2);
		float dvdy = (d->u[N].y - d->u[S].y) / (2);
		/*dudx *= div;
		dudy *= div;
		dvdx *= div;
		dvdy *= div;*/
	

		//pressure
		P[0] = d->p[index];
		P[1] = d->p[E];
		P[2] = d->p[W];
		P[3] = d->p[S];
		P[4] = d->p[N];

		//density
		P[5] = d->rho[index];
		P[6] = d->rho[E];
		P[7] = d->rho[W];
		P[8] = d->rho[S];
		P[9] = d->rho[N];

		//temperature
		P[10] = d->T[index];
		P[11] = d->T[E];
		P[12] = d->T[W];
		P[13] = d->T[S];
		P[14] = d->T[N];


		//compute correction factor and stress tensor
		float parx = (correction_factor(P[6], P[11], d->u[E].x) - correction_factor(P[7], P[12], d->u[W].x)) * 0.5f;
		float pary = (correction_factor(P[9], P[14], d->u[N].y) - correction_factor(P[8], P[13], d->u[S].y)) * 0.5f;

		//Stress tensor(u);

		//compute equilibrium moment values aeq
		float C = 0.0f;// 0.3333f * (P[10] - 1.0f);
		float uu = u.x * u.x;
		float uv = u.x * u.y;
		float vv = u.y * u.y;
		aeq[0] = 1.0f;
		aeq[1] = u.x;
		aeq[2] = u.y;
		aeq[3] = (uu + C); // xx
		aeq[4] = (uv);  // xy
		aeq[5] = (vv + C); // yy
		aeq[6] = (uu + C) * u.y; // xxy
		aeq[7] = (vv + C) * u.x;//yyx
		aeq[8] = (uu * vv + C * C + C * (uu + vv));
		aeq[9] = uu * u.x;
		aeq[10] = vv * u.y;
		a[1] = 0.0f;
		a[2] = 0.0f;
		a[3] = 0.0f;
		float vi = 1.0f/tref;
		//compute feq, psi and off eq moments
		for (int i = 0; i < 9; i++) {
			psi[i] =  w[i] * 4.5f * (H[i][3] * parx + H[i][5] * pary) * vi * vi;
			feq[i] = w[i] * feq_func(P[5], H[i], aeq, vi);
			float apr = (ff[i][index]  - feq[i] +   0.5f * psi[i]);
			d->correction[i][index] = psi[i];
			a[1] += H[i][3] * apr; //axx
			a[2] += H[i][4] * apr; //axy
			a[3] += H[i][5] * apr; //ayy
		}
		//compute off equilibrium moments
		float axx = -(dudx * 2 - 0.4f * (dudx + dvdy))  * tau_ * P[5] * cs * cs;
		float axy = -(dudy + dvdx) * tau_ * P[5] * cs * cs ;
		float ayy = -(dvdy * 2 - 0.4f * (dudx + dvdy))  * tau_ * P[5] * cs * cs;

		a[1] = sigma * (a[1] - 1.0f/3.0f * (a[1] + a[3])) - (1.0f - sigma) * axx;
		a[2] = sigma * a[2] - (1.0f - sigma) * axy;
		a[3] = sigma * (a[3] - 1.0f / 3.0f * (a[1] + a[3])) - (1.0f - sigma) * ayy;
		a[4] = a[1] * u.y + 2 * u.x * a[2];
		a[5] = a[3] * u.x + 2 * u.y * a[2];
		a[6] = 2 * (u.x * a[5] + u.y * a[4]) + (C - uu) * a[3] + (C - vv) * a[1] - 4 * uv * a[2];

		//now compute f1, f+ and subsequently stream
		// 0   1    2   3    4    5    6     7     8
		// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
		float inv2 = 1 / (cs * cs);
		for (int i = 0; i < 9; i++) {
			float f1 = w[i] * (
				(H[i][3] * a[1] + 2 * H[i][4] * a[2] + H[i][5] * a[3]) * 0.5f * inv2 * inv2  +
				(3 * H[i][6] * a[4] + 3 * H[i][7] * a[5]) * inv2 * inv2 * inv2 * 0.16666666666666666666f + 
				(6 * H[i][8] * a[6]) * inv2 * inv2 * inv2 * inv2 * 0.04166666666666666666666666666667f
			);
			feq[i] = feq[i] + psi[i] * 0.5f +(1 - 1.0f / tau_) * f1;
			int write_x = idx + es[i].x;
			int write_y = idy + es[i].y;
			//handle periodic boundary
			if (write_x == -1) {
				write_x = NX - 1;
			}
			if (write_y == -1) {
				write_y = (NY - 1);
			}
			if (write_x == NX) {
				write_x = 0;
			}
			if (write_y == NY) {
				write_y = 0;
			}
			fs[i][write_x + write_y * NX] = feq[i];
		}
	}

	__global__ void compute_micro2(Domain* d, float** ff, float** fs) {
		uint idx = threadIdx.x + blockDim.x * blockIdx.x;
		uint idy = threadIdx.y + blockDim.y * blockIdx.y;
		uint index = idx + idy * NX;
		uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
		uint W = idx == 0 ? NX - 1 + idy * NX : index - 1;
		uint E = idx == NX - 1 ? idy : index + 1;
		uint N = idy == NY - 1 ? idx : index + NX;
		uint S = idy == 0 ? idx + NX * (NY - 1) : index - NX;

		// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
		__shared__ float H[9][9];
		vec2INT es[9] = {
		{ 0,  0},
		{ 1,  0},
		{ 0,  1},
		{-1,  0},
		{ 0, -1},
		{ 1,  1},
		{-1,  1},
		{-1, -1},
		{ 1, -1},
		};
		//latice constants
		__shared__ vec2 e[9];
		__shared__ float w[9];

		if (threadIdx.x < 9 && threadIdx.y == 0) {
			for (int i = 0; i < 9; i++) {
				H[threadIdx.x][i] = d->hermite[threadIdx.x][i];
			}
		}
		if (threadIdx.x < 9 && threadIdx.y == 0) {
			e[threadIdx.x].x = d->e[threadIdx.x].x;
			e[threadIdx.x].y = d->e[threadIdx.x].y;
			w[threadIdx.x] = d->w[threadIdx.x];
		}
		__syncthreads();


		//{0, -x, + x, -y, + y}
		vec2 u;
		float P[15];
		float feq[9], a[9], aeq[11], psi[9];

		//read the GLOBAL field variables to registers (harsh on registers)
		u = d->u[index];
		float div = 1.0f / (cs * cs);
		float dudx = (d->u[E].x - d->u[W].x) / (2);
		float dudy = (d->u[N].x - d->u[S].x) / (2);
		float dvdx = (d->u[E].y - d->u[W].y) / (2);
		float dvdy = (d->u[N].y - d->u[S].y) / (2);
		/*dudx *= div;
		dudy *= div;
		dvdx *= div;
		dvdy *= div;*/


		//pressure
		P[0] = d->p[index];
		P[1] = d->p[E];
		P[2] = d->p[W];
		P[3] = d->p[S];
		P[4] = d->p[N];

		//density
		P[5] = d->rho[index];
		P[6] = d->rho[E];
		P[7] = d->rho[W];
		P[8] = d->rho[S];
		P[9] = d->rho[N];

		//temperature
		P[10] = d->T[index];
		P[11] = d->T[E];
		P[12] = d->T[W];
		P[13] = d->T[S];
		P[14] = d->T[N];


		//compute correction factor and stress tensor
		float parx = (correction_factor(P[6], P[11], d->u[E].x) - correction_factor(P[7], P[12], d->u[W].x)) * 0.5f;
		float pary = (correction_factor(P[9], P[14], d->u[N].y) - correction_factor(P[8], P[13], d->u[S].y)) * 0.5f;

		//Stress tensor(u);

		//compute equilibrium moment values aeq
		float C = 0.0f;// 0.3333f * (P[10] - 1.0f);
		float uu = u.x * u.x;
		float uv = u.x * u.y;
		float vv = u.y * u.y;
		aeq[0] = 1.0f;
		aeq[1] = u.x;
		aeq[2] = u.y;
		aeq[3] = (uu + C); // xx
		aeq[4] = (uv);  // xy
		aeq[5] = (vv + C); // yy
		aeq[6] = (uu + C) * u.y; // xxy
		aeq[7] = (vv + C) * u.x;//yyx
		aeq[8] = (uu * vv + C * C + C * (uu + vv));
		aeq[9] = uu * u.x;
		aeq[10] = vv * u.y;
		a[0] = 0.0f;
		a[1] = 0.0f;
		a[2] = 0.0f;
		a[3] = 0.0f;
		float vi = 1.0f / tref;
		float inv2 = 1 / (cs * cs);
		//compute feq, psi and off eq moments
		for (int i = 0; i < 9; i++) {
			psi[i] = w[i] * 4.5f * (H[i][3] * parx + H[i][5] * pary) * vi * vi;
			feq[i] = w[i] * feq_func(P[5], H[i], aeq, vi);
			float apr = (ff[i][index] - feq[i] + 0.5f * psi[i]);
			d->correction[i][index] = psi[i];
			a[0] += es[i].x * es[i].x * apr; //axx
			a[1] += es[i].y * es[i].x * apr; //axx
			a[2] += es[i].y * es[i].y * apr; //axx
			float neq = w[i] * ((H[i][3] * a[0] + H[i][4] * a[1] * 2  + H[i][5] * a[2]) * inv2 * inv2 * 0.5f + (H[i][6] *  (3 * u.y * a[0] + u.x * a[1] * 2) + 3 * H[i][7] * (u.x * a[2] + u.y * a[1] * 2)) * inv2 * inv2 * inv2 * 0.16666666666666666666f);
			feq[i] = feq[i] + psi[i] * 0.5f; +(1 - 1.0f / tau_) * neq;
		}
		//compute off equilibrium moments
		

		//now compute f1, f+ and subsequently stream
		// 0   1    2   3    4    5    6     7     8
		// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
		
		for (int i = 0; i < 9; i++) {
			int write_x = idx + es[i].x;
			int write_y = idy + es[i].y;
			//handle periodic boundary
			if (write_x == -1) {
				write_x = NX - 1;
			}
			if (write_y == -1) {
				write_y = (NY - 1);
			}
			if (write_x == NX) {
				write_x = 0;
			}
			if (write_y == NY) {
				write_y = 0;
			}
			fs[i][write_x + write_y * NX] = feq[i];
		}
	}

__global__ void stream(Domain* d, float** ff, float** fs) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
	uint W = idx == 0 ? NX - 1 + idy * NX : index - 1;
	uint E = idx == NX - 1 ? idy : index + 1;
	uint N = idy == NY - 1 ? idx : index + NX;
	uint S = idy == 0 ? idx + NX * (NY - 1) : index - NX;

	vec2INT es[9] = {
	{ 0,  0},
	{ 1,  0},
	{ 0,  1},
	{-1,  0},
	{ 0, -1},
	{ 1,  1},
	{-1,  1},
	{-1, -1},
	{ 1, -1},
	};

	for (int i = 0; i < 9; i++) {
		int write_x = idx + es[i].x;
		int write_y = idy + es[i].y;
		//handle periodic boundary
		if (write_x == -1) {
			write_x = NX - 1;
		}
		if (write_y == -1) {
			write_y = (NY - 1);
		}
		if (write_x == NX) {
			write_x = 0;
		}
		if (write_y == NY) {
			write_y = 0;
		}
		fs[i][write_x + write_y * NX] = ff[i][index];
	}
}
__global__ void initialize_micro(Domain* d, float** ff, float** fs) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	uint threadid = threadIdx.x + threadIdx.y * blockDim.x;
	uint W = idx == 0 ? NX - 1 + idy * NX : index - 1;
	uint E = idx == NX - 1 ? idy : index + 1;
	uint N = idy == NY - 1 ? idx : index + NX;
	uint S = idy == 0 ? idx + NX * (NY - 1) : index - NX;

	// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
	__shared__ float H[9][9];
	vec2INT es[9] = {
	{ 0,  0},
	{ 1,  0},
	{ 0,  1},
	{-1,  0},
	{ 0, -1},
	{ 1,  1},
	{-1,  1},
	{-1, -1},
	{ 1, -1},
	};
	//latice constants
	__shared__ vec2 e[9];
	__shared__ float w[9];

	if (threadIdx.x < 9 && threadIdx.y == 0) {
		for (int i = 0; i < 9; i++) {
			H[threadIdx.x][i] = d->hermite[threadIdx.x][i];
		}
	}
	if (threadIdx.x < 9 && threadIdx.y == 0) {
		e[threadIdx.x].x = d->e[threadIdx.x].x;
		e[threadIdx.x].y = d->e[threadIdx.x].y;
		w[threadIdx.x] = d->w[threadIdx.x];
	}
	__syncthreads();


	// {0, -x, + x, -y, + y
	float P[15];
	float feq[9], a[9], aeq[9], psi[9];

	//read the GLOBAL field variables to registers (harsh on registers)
	//u[0] = d->u[index];

	float dudx = (d->u[E].x - d->u[W].x) / (2);
	float dudy = (d->u[N].x - d->u[S].x) / (2);
	float dvdx = (d->u[E].y - d->u[W].y) / (2);
	float dvdy = (d->u[N].y - d->u[S].y) / (2);


	//pressure
	P[0] = d->p[index];
	P[1] = d->p[E];
	P[2] = d->p[W];
	P[3] = d->p[S];
	P[4] = d->p[N];

	//density
	P[5] = d->rho[index];
	P[6] = d->rho[E];
	P[7] = d->rho[W];
	P[8] = d->rho[S];
	P[9] = d->rho[N];

	//temperature
	P[10] = d->T[index];
	P[11] = d->T[E];
	P[12] = d->T[W];
	P[13] = d->T[S];
	P[14] = d->T[N];


	//compute correction factor and stress tensor

	
	//Stress tensor(u);

	//compute equilibrium moment values aeq
	float parx = (correction_factor(P[6], P[11], d->u[E].x) - correction_factor(P[7], P[12], d->u[W].x)) * 0.5f;
	float pary = (correction_factor(P[9], P[14], d->u[N].y) - correction_factor(P[8], P[13], d->u[S].y)) * 0.5f;

	//Stress tensor(u);

	//compute equilibrium moment values aeq
	vec2 u = d->u[index];
	float C = 0.0f;// 0.3333f * (P[10] - 1.0f);
	float uu = u.x * u.x;
	float uv = u.x * u.y;
	float vv = u.y * u.y;
	aeq[0] = 1.0f;
	aeq[1] = u.x;
	aeq[2] = u.y;
	aeq[3] = (uu + C); // xx
	aeq[4] = (uv);  // xy
	aeq[5] = (vv + C); // yy
	aeq[6] = (uu + C) * u.y; // xxy
	aeq[7] = (vv + C) * u.x;//yyx
	aeq[8] = (uu * vv + C * C + C * (uu + vv));
	aeq[9] = uu * u.x;
	aeq[10] = vv * u.y;
	a[1] = 0.0f;
	a[2] = 0.0f;
	a[3] = 0.0f;
	float vi = 1.0f / tref;
	//compute feq, psi and off eq moments
	for (int i = 0; i < 9; i++) {
		psi[i] = w[i] * 4.5f * (H[i][3] * parx + H[i][5] * pary) * vi * vi;
		feq[i] = w[i] * feq_func(P[5], H[i], aeq, vi);
		float apr = (ff[i][index] - feq[i] + 0.5f * psi[i]);
		d->correction[i][index] = psi[i];
		a[1] += H[i][3] * apr; //axx
		a[2] += H[i][4] * apr; //axy
		a[3] += H[i][5] * apr; //ayy
	}
	//compute off equilibrium moments
	float axx = -(dudx * 2 + 0.4f * (dudx + dvdy)) * tau_ * P[0];
	float axy = -(dudy + dvdx) * tau_ * P[0];
	float ayy = -(dvdy * 2 + 0.4f * (dudx + dvdy)) * tau_ * P[0];

	a[1] = axx;
	a[2] = axy;
	a[3] = ayy;
	a[4] = a[1] * u.y + 2 * u.x * a[2];
	a[5] = a[3] * u.x + 2 * u.y * a[2];
	a[6] = 2 * (u.x * a[5] + u.y * a[4]) + (C - uu) * a[3] + (C - vv) * a[1] - 4 * uv * a[2];

	//now compute f1, f+ and subsequently stream
	// 0   1    2   3    4    5    6     7     8
	// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY
	float inv2 = 1 / (cs * cs);
	for (int i = 0; i < 9; i++) {
		float f1 = w[i] * (
			(H[i][3] * a[1] + 2 * H[i][4] * a[2] + H[i][5] * a[3]) * 0.5f * inv2 * inv2 +
			(3 * H[i][6] * a[4] + 3 * H[i][7] * a[5]) * inv2 * inv2 * inv2 * 0.16666666666666666666f +
			(6 * H[i][8] * a[6]) * inv2 * inv2 * inv2 * inv2 * 0.04166666666666666666666666666667f
			);
		feq[i] = feq[i];// +psi[i] * 0.5f + (1 - 1 / tau_) * f1;
		int write_x = idx + es[i].x;
		int write_y = idy + es[i].y;
		//handle periodic boundary
		if (write_x == -1) {
			write_x = NX - 1;
		}
		if (write_y == -1) {
			write_y = (NY - 1);
		}
		if (write_x == NX) {
			write_x = 0;
		}
		if (write_y == NY) {
			write_y = 0;
		}
		fs[i][write_x + write_y * NX] = feq[i];
	}
}

__global__ void compute_macro(Domain* d, float** ff) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y;
	uint index = idx + idy * NX;
	uint threadid = threadIdx.x + threadIdx.y * blockDim.x;

	float u = 0.0f;
	float v = 0.0f;
	float rho = 0.0f;
	vec2 vel = d->u[index];
	//if (d->mask[index])return;
	for (int i = 0; i < 9; i++) {
		float f = ff[i][index];
		rho += f;
		float psi = 0.5f * d->correction[i][index];
		u +=  (d->e[i].x) * ( f + psi);
		v +=  (d->e[i].y) * ( f + psi);
	}
	if (rho == 0) {
		d->u[index].x = 0.0f;
		d->u[index].y = 0.0f;
		d->rho[index] = rho;
		return;
	}
	float inv = 1.0f / rho;
	d->u[index] = { u * inv  ,  v * inv  };
	d->rho[index] = rho;
	d->p[index] = rho * cs * cs;
	d->T[index] = 1.0f;
}

__global__ void gradient(Domain* d, float* buffer, bool* mask, int n, float sc, int state) {
	uint idx = threadIdx.x + blockDim.x * blockIdx.x + 1;
	uint idy = threadIdx.y + blockDim.y * blockIdx.y + 1;
	if (idx >= NX - 1 || idy >= NY - 1)return;
	float dx = d->u[idx + 1 + idy * n].y - d->u[idx - 1 + idy * n].y;
	float dy = d->u[idx + (idy + 1) * n].x - d->u[idx + (idy - 1) * n].x;
	uint index = idx + idy * NX;
	if (idx == 300 || idx == 250 || idx == 350) {
		buffer[index] = 1.0f;
		return;
	}
	float c2 = 1.0f / csoi;
	float vx = d->u[idx + idy * n].x;
	float vy = d->u[idx + idy * n].y;
	if (state == 0) {
		buffer[idx + n * idy] = 1 * (0.5f + (vx / cs) / 0.0016f * 0.5f);
		return;
	}
	if (state == 1) {
		buffer[idx + n * idy] = sc * (vx * vx / cs);
		return;
	}
	if (state == 2) {
		buffer[idx + n * idy] = sc * (0.5f - ((d->u[idx + idy * n].x) * 5 * 625) * 0.5f);
		if (idx == 300)buffer[idx + n * idy] = 0.0f;
		return;
	}
	if (state == 3) {
		buffer[idx + n * idy] = sc * (vx - 0.5f);
		return;
	}
	if (state == 4) {
		buffer[idx + n * idy] = (0.5f - (d->p[index] / 0.0065857f - 1.0f)) * sc;
		return;
	}
	if (state == 5) {
		buffer[idx + n * idy] =  0.5f + 0.5f * (d->p[index] / (cs * cs) - 1.0f) / 0.0015f;
		return;
	}
	if (state == 6) {
		buffer[idx + n * idy] = sc * abs(d->rho[index] - 1.0f);
		return;
	}
	buffer[idx + n * idy] = sc * abs(dy - dx);//0.2f - 500000 * (vfield[idx + idy * n].x - dens);
}



__global__ void normalize(float* buffer) {
	uint id = threadIdx.x + blockIdx.x * blockDim.x;
	uint threadid = threadIdx.x;
	uint begin = blockIdx.x * blockDim.x;

}
