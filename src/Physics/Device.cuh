//
// Created by domin on 09/05/2025.
//

#ifndef LBM_DEVICE_CUH
#define LBM_DEVICE_CUH
#pragma once
#include <cuda_runtime.h>
#include "../settings/log.h"


class Device {
public:
    cudaDeviceProp prop;
    int id;
    unsigned int mem_avail, mem_tot;
    Device(unsigned int id);
    void info(Log& log);
};


#endif //LBM_DEVICE_CUH
