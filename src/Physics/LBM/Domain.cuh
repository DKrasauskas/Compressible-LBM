#pragma once
#include "../../settings/setup.cuh"
#define FP32 4
#define FP64 8
struct Domain {
	float** f, ** fbuffer;
	float** correction;
	float* w;
	bool* mask;
	vec2* u, * e;
	float** hermite;
	// scalar fields
	float* p, * T, *T_buffer, * s, *rho;
};

struct SolveSet{
    void* f, *f_buffer;
    void* corrections;
    void* w;
    //uint dtype  = 4;//default -> FP32
};