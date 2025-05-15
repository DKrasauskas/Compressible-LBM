#pragma once
#include <sstream>
#include <fstream>
#include <string>
#include <iostream>
#include <glad.h>
#include <glfw3.h>
#include "../../settings/log.h"


using namespace std;

class Shader {
public:
    unsigned int ID;
    Shader(const char* inputVertex, const char* inputFragment, Log& log);
    Shader(const char* inputGeneric,  Log& log);
    ~Shader();
    char* Parse(string input, Log& log);
    void BuildShaders(unsigned int& shader, const char* source, uint32_t shader_type, std::string& type, Log& log);
    void handle() const;
    void Link(unsigned int& program, Log& log);
    bool success;
};
