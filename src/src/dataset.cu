//
// Created by domin on 11/05/2025.
//

#include "../Physics/dataset.cuh"
DatasetFP32::DatasetFP32(long long X, long long Y, int d, int q) {
    xy = X * Y;
    float** f_host = (float**)malloc( sizeof(float*) * q);
    float** f_host_buffer = (float**)malloc( sizeof(float*) * q);
    for(int i = 0 ; i < q; i ++){
        cudaMalloc(&f_host[i], sizeof(float) * xy);
        cudaMalloc(&f_host_buffer[i], sizeof(float) * xy);
    }
    cudaMalloc(&f, sizeof(float*) * q);
    cudaMalloc(&f_buffer, sizeof(float*) * q);

    cudaMemcpy(f, f_host, sizeof(float) * q, cudaMemcpyHostToDevice);
    cudaMemcpy(f_buffer, f_host_buffer, sizeof(float) * q, cudaMemcpyHostToDevice);
    free(f_host);
    free(f_host_buffer);
}


DatasetFP32::DatasetFP32(long long X, long long Y, Log& log, int d, int q) {
    mem_size = 0;
    bool success = true;
    cudaError_t cuda_alloc;
    log.new_state("DatasetFP32");
    xy = X * Y;
    mem_size = xy *  (q * 2 + d + 3) * sizeof(float);
    log.log_state(std::to_string(mem_size));
    size_t dev_mem_avail, dev_mem_tot;
    cudaMemGetInfo(&dev_mem_avail, &dev_mem_tot);
    log.log_state(std::to_string(dev_mem_avail));
    if(dev_mem_avail  < mem_size){
        log.new_state("Unable to allocate: not enough memory on the device");
        return;
    }
    if(dev_mem_tot  < mem_size){
        log.new_state("Unable to allocate: Exceeds total device memory");
        return;
    }
    // dist fnc alloc
    float** f_host = (float**)malloc( sizeof(float*) * q);
    float** f_host_buffer = (float**)malloc( sizeof(float*) * q);
    if((nullptr == f_host) || (f_host_buffer == nullptr)){
        free(f_host);
        free(f_host_buffer);
        goto exit;
    }
    log.log_mem(sizeof(float*) * q * 2);
    for(int i = 0 ; i < q; i ++){
        cuda_alloc = cudaMalloc(&f_host[i], sizeof(float) * xy);
        cuda_alloc != cudaSuccess ? success = false: success &= 1;
        cuda_alloc = cudaMalloc(&f_host_buffer[i], sizeof(float) * xy);
        cuda_alloc != cudaSuccess ? success = false: success &= 1;
        log.log_mem_dev(sizeof(float) * xy * 2);
    }
    cuda_alloc = cudaMalloc(&f, sizeof(float*) * q);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    cuda_alloc = cudaMalloc(&f_buffer, sizeof(float*) * q);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    log.log_mem_dev(sizeof(float*) * q * 2);

    cuda_alloc = cudaMemcpy(f, f_host, sizeof(float*) * q, cudaMemcpyHostToDevice);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    cuda_alloc = cudaMemcpy(f_buffer, f_host_buffer, sizeof(float*) * q, cudaMemcpyHostToDevice);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;

    //macroscopic alloc
    cuda_alloc = cudaMalloc(&rho, sizeof(float) * xy);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    log.log_mem_dev(sizeof(float) * xy);
    cuda_alloc = cudaMalloc(&p, sizeof(float) * xy);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    log.log_mem_dev(sizeof(float) * xy);
    cuda_alloc = cudaMalloc(&v, sizeof(vec2FP32) * xy);
    cuda_alloc != cudaSuccess ? success = false: success &= 1;
    log.log_mem_dev(sizeof(float) * xy);

    if(!success){
        log.log_state("initialization failed.");
        goto dealloc;
    }
    else{
        log.log_state("succeeded.");
        size_t  alloc_mem;
        cudaMemGetInfo(&alloc_mem, &dev_mem_tot);
        log.log_state("Allocated " + std::to_string((-alloc_mem+dev_mem_avail) * 1E-6) + " mb on Device");
        free(f_host_buffer);
        free(f_host);
    }
    exit:
    return;

    dealloc:
    cudaFree(rho);
    cudaFree(p);
    cudaFree(v);
    for(int i = 0; i < q; i ++){
        cudaFree(f_host[i]);
        cudaFree(f_host_buffer[i]);
    }
    cudaFree(f);
    cudaFree(f_buffer);
    free(f_host_buffer);
    free(f_host);
}


