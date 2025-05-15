#pragma once
#include "LBM/Domain.cuh"
#include "initial-conditions.h"
#include "LBM/differentials.h"
#include "GPU-code/stress-tensor.cuh"
#include "Runge-Kutta.cuh"
#include "LBM/correction-Factor.cuh"
#include "GPU-code/equilibrium.cuh"
#include "Deprecated/streaming_kernel.cuh"
#include "GPU-code/macros.cuh"
#include "LBM/initial.cuh"
#include "GPU-code/physics.cuh"

namespace LBM {
	Domain* __init__(int grid_size, vec2 e[9], float w[9]) {
		Domain* d = new Domain;
		float mem = NX * NY * sizeof(float);
       // log.new_state("LBM INIT");
        size_t free_mem = 0;
        size_t total_mem = 0;
        cudaError_t err = cudaMemGetInfo(&free_mem, &total_mem);
		mem * 1E-9 > 6 ? throw : NULL;
        cudaError_t alloc;
		alloc = cudaMalloc(&d->p, sizeof(float) * NX * NY);
		cudaMalloc(&d->s, sizeof(float) * NX * NY);
		cudaMalloc(&d->T, sizeof(float) * NX * NY);
		cudaMalloc(&d->T_buffer, sizeof(float) * NX * NY);
		cudaMalloc(&d->rho, sizeof(float) * NX * NY);
		cudaMalloc(&(d->f), sizeof(float*) * 9);
		cudaMalloc(&(d->hermite), sizeof(float*) * 9);
		cudaMalloc(&(d->correction), sizeof(float*) * 9);
		cudaMalloc(&d->fbuffer, sizeof(float*) * 9);
		cudaMalloc(&d->e, sizeof(vec2) * 9);
		cudaMalloc(&d->u, sizeof(vec2) * NX * NY);
		cudaMalloc(&d->w, sizeof(float) * 9);
		fhost = (float**)malloc(sizeof(float*) * 9);
		host_buff = (float**)malloc(sizeof(float*) * 9);
		float** cor_buff = (float**)malloc(sizeof(float*) * 9);
		float** hermite_buffer = (float**)malloc(sizeof(float*) * 11);
		for (int i = 0; i < 9; i++) {
			e[i].x *= tref;
			e[i].y *= tref;
		}
		float** hermite_polynomials = hermite_Polynomials(e);
		for (int i = 0; i < 9; i++) {
			cudaMalloc(&fhost[i], sizeof(float) * grid_size);
			cudaMalloc(&host_buff[i], sizeof(float) * grid_size);
			cudaMalloc(&cor_buff[i], sizeof(float) * grid_size);
			cudaMalloc(&hermite_buffer[i], sizeof(float) * 11);
			cudaMemcpy(hermite_buffer[i], hermite_polynomials[i], sizeof(float) * 11, cudaMemcpyHostToDevice);
		}
		
		cudaMemcpy(d->hermite, hermite_buffer, sizeof(float*) * 9, cudaMemcpyHostToDevice);
		cudaMemcpy(d->f, fhost, sizeof(float*) * 9, cudaMemcpyHostToDevice);
		cudaMemcpy(d->fbuffer, host_buff, sizeof(float*) * 9, cudaMemcpyHostToDevice);
		cudaMemcpy(d->correction, cor_buff, sizeof(float*) * 9, cudaMemcpyHostToDevice);
		cudaMemcpy(d->e, e, sizeof(vec2) * 9, cudaMemcpyHostToDevice);
		cudaMemcpy(d->w, w, sizeof(float) * 9, cudaMemcpyHostToDevice);
		free(fhost);
		free(host_buff);
		free(cor_buff);
		free(hermite_buffer);
		free(hermite_polynomials);
		return d;
	}
	bool* obstacle(float theta) {
		bool* mem2 = (bool*)malloc(sizeof(bool) * NX * NY);
		for (int x = 0; x < NX; x++) {
			for (int y = 0; y < NY; y++) {
				if (show_airfoil) {
					float cx = (x - NX / 8) * cos(theta) - (y - NY / 2) * sin(theta);
					float cy = (x - NX / 4) * sin(theta) + (y - NY / 2) * cos(theta);
					float dx = (cx) * 0.003f;
					if (dx >= 0 && dx < 1) {
						// NACA symmetric airfoil function
						float dy = 0.2969 * sqrt(dx) - 0.126 * dx - 0.3516 * dx * dx + 0.2843 * dx * dx * dx - 0.1015 * dx * dx * dx * dx;
						mem2[x + y * NX] = 0;
						if (abs(dy * 2) > 0.008f * abs(cy)) mem2[x + y * NX] = 1.0f;
					}
				}
				else {
					// mem2[x + y * NX] = 0;
					// mem2[x + y * NX] = 0;
					 /* float boundary = (x - NX / 4) * (x - NX /4) + (y - NY / 2) * (y - NY / 2);
					  if (boundary< 200) {
						  mem2[x + y * NX] = 1;
					  }
					  else {
						  mem2[x + y * NX] = 0;
					  }*/
					/*float boundary = (x - NX / 5) * (x - NX / 5) + (y - NY / 2) * (y - NY / 2);
					if (boundary < 1000) {
						mem2[x + y * NX] = 1;
					}
					else {
						mem2[x + y * NX] = 0;
					}*/
					/*     if (( (x - 500) + y > 1000 || -(x - 500) + y < 0) &&  x >40 && x < 800 && y > 10 && y  < 1000) {
							 mem2[x + y * NX] = 1;
						 }
						 else {

									 mem2[x + y * NX] = 0;


						 }*/
						 /*  if (x > 200 && x < 202 && y > 200 && y < 302 ){
							   mem2[x + y * NX] = 1;
						   }
						   else {
							   mem2[x + y * NX] = 0;
						   }*/

						   /*  if (+x - y > 0 && x > 500) {
								 mem2[x + y * NX] = 1;
							 }
							 else {
								 mem2[x + y * NX] = 0;
							 }*/
				}
			}
		}
		return mem2;
	}
	void handle_error(cudaError t) {
		if (t != cudaSuccess) {
			printf("CUDA errors: %s\n", cudaGetErrorString(t));
			throw;
		}
	}
	void initial_conditions(Domain ** dev, Domain ** host) {
		initialize_macro<<<blockH, threadH>>>(*dev);
		cudaDeviceSynchronize();
		cudaError_t err = cudaGetLastError();
		if (err != cudaSuccess) {
			printf("CUDA error 0: %s\n", cudaGetErrorString(err));
		}
		initialize_micro<<<blockH, threadH>>>(*dev, (*host)->f, (*host)->fbuffer);	
		cudaDeviceSynchronize();
		err = cudaGetLastError();
		if (err != cudaSuccess) {
			printf("CUDA error 1: %s\n", cudaGetErrorString(err));
		}
	}
    void swap_buffers(void** buff1, void** buff2){
        void* auxiliary = *buff2;
        *buff2 = *buff1;
        *buff1 =auxiliary;
    }
	void job(Domain** dev, Domain ** host, int count, int counter) {
		compute_micro <<<blockH, threadH>>>(*dev, (*host)->f, (*host)->fbuffer);
		cudaDeviceSynchronize();
		handle_error(cudaGetLastError());
        swap_buffers(reinterpret_cast<void **>(&(*host)->f), reinterpret_cast<void **>(&(*host)->fbuffer));
		compute_macro<<<blockH, threadH>>>(*dev, (*host)->f);
		cudaDeviceSynchronize();
		handle_error(cudaGetLastError());

		//post processing
		gradient<<<blockH, threadH>>>(*dev, output, (*host)->mask, NX, map_scale, state);
		cudaDeviceSynchronize();
		handle_error(cudaGetLastError());
	}
	Domain* begin(Domain ** dev) {
		cudaMalloc(dev, sizeof(Domain));
		Domain* host = __init__(NX * NY, es, weights);
		bool* ob = obstacle(0.1);
		cudaMalloc(&host->mask, sizeof(bool) * NX * NY);
		cudaMemcpy(host->mask, ob, sizeof(bool) * NX * NY, cudaMemcpyHostToDevice);
		cudaMemcpy(*dev, host, sizeof(Domain), cudaMemcpyHostToDevice);
		//initial_conditions(dev, &host);
		return host;
	}
	
	void solve(Domain* host, Domain* dev) {
//		compressible_collide << <blockH, threadH >> > (dev, host->f, host->fbuffer);
	//	cudaDeviceSynchronize();
		float** aux = host->f;
		host->f = host->fbuffer;
		host->fbuffer = aux;
		compute_macros <<<blockH, threadH >>> (dev, state);
		sPDE <<<blockH, threadH >>> (dev, NX);
		getT <<<blockH, threadH >>> (dev, output);
		gradient <<<blockH, threadH >>> (dev, output, host->mask, NX, map_scale, state);
		cudaDeviceSynchronize();
	}

	void stopv(Domain* host) {
		gradient <<<blockH, threadH >>> (host, output, host->mask, NX, map_scale, state);
		cudaDeviceSynchronize();
	}

}
