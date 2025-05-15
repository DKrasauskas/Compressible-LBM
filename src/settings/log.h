//
// Created by domin on 07/05/2025.
//

#ifndef LBM_LOG_H
#define LBM_LOG_H

#endif //LBM_LOG_H
#pragma once
#include <vector>
#include <string>
#include <fstream>


class Log{
public:
    const char* output_name;
    const char* output_path;
    std::ofstream log_file;
    unsigned int written_index;
    std::vector<std::string> log;
    void begin();
    void log_state(std::string data);
    void log_mem(unsigned int size);
    void log_cuda_mem(std::string device, unsigned int net, unsigned int available);
    void end();
    void new_state();
    void new_state(std::string name);
    void to_file();
    void log_mem_dev(unsigned int size);
};
