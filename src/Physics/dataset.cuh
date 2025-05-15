//
// Created by domin on 11/05/2025.
//

#ifndef LBM_DATASET_CUH
#define LBM_DATASET_CUH
#pragma once
#include "../settings/log.h"

struct vec2FP32{
    float x, y;
};

struct vec2FP64{
    double x, y;
};

class DatasetFP32{
public:
    void* f, *f_buffer;
    void* p, *rho;
    vec2FP32* v;
    long long dtype, x, y, xy, mem_size;

    DatasetFP32(long long X, long long Y, int d = 2, int q = 9);
    DatasetFP32(long long X, long long Y,Log& log, int d = 2, int q = 9);
};

class DatasetFP64{
    DatasetFP64(int X, int Y, int d, int q);
//dev ptr
    void* f, *f_buffer;
    unsigned int dtype, x, y, xy;
};
#endif //LBM_DATASET_CUH
