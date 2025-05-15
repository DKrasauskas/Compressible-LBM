//
// Created by domin on 09/05/2025.
//

#include "../Physics/Device.cuh"
#include "../Physics/Device.cuh"

void Device::info(Log &log) {
    log.new_state( "CUDA");
    log.log_state(std::string ("Device ") + this->prop.name);
    log.log_state(std::string ("Memory ") + std::to_string(this->mem_tot - this->mem_avail) + "MB used");
    log.log_state(std::string ("Memory ") + std::to_string(this->mem_avail) + "MB avail");
}
Device::Device(unsigned int id) {
    size_t net, avail;
    cudaGetDeviceProperties(&this->prop, id);
    cudaMemGetInfo(&avail, &net);
    this->mem_tot = (float)net * (1E-6);
    this->mem_avail = (float)avail * (1E-6);
}