//
// Created by domin on 07/05/2025.
//
#include "../settings/log.h"


void Log::log_state(std::string data) {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file << data << "\n";
}

void Log::begin() {
    this->log_file.open(this->output_path);
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
}
void Log::end() {
    this->log_file.close();
}

void Log::log_mem(unsigned int size) {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file << "allocating " << size << "bytes" << "\n";
}
void Log::log_mem_dev(unsigned int size) {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file << "allocating (device) " << size << "bytes" << "\n";
}
void Log::log_cuda_mem(std::string device, unsigned int total_mem, unsigned int free_mem) {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file << "CUDA Properties\n" << "Device " << device << "\n VRAM " << total_mem << " total\n VRAM " << free_mem << " avail\n";
}
void Log::new_state() {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file << "_____________________________________________________________" << "\n";
}

void Log::new_state(std::string name) {
    if (!log_file.is_open()) {
        throw std::runtime_error("Unable to open log file");
    }
    this->log_file<<
                   + "\n___________________________"
                   + name
                   + "______________________________\n"<< "\n";
}