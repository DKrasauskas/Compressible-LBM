#pragma once
#include <sstream>
#include <fstream>
#include <string>
#include <iostream>
#include <glad.h>
#include <glfw3.h>

#define uint unsigned int

class Buffer {
public:
	uint VAO, VBO, EBO;
	Buffer(void* vertex_memory, void* indice_memory, int vertex_size, int indice_size);
	~Buffer();
};