#pragma once

struct resource {
    cudaGraphicsResource* cr;
    unsigned int* ssbo;
};

struct scene {
    unsigned int* compute, * vertex, * texture;
    resource* r;
};

unsigned int* make_texture() {
    unsigned int* texture = new unsigned int;
    glGenTextures(1, texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, *texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, NX, NY, 0, GL_RGBA, GL_FLOAT, nullptr);
    glBindImageTexture(0, *texture, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}

resource* make_buffer() {
    resource* r = new resource;
    r->ssbo = new unsigned int;
    glGenBuffers(1, r->ssbo);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, *r->ssbo);
    glBufferData(GL_SHADER_STORAGE_BUFFER, NX * NY * sizeof(float), nullptr, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
    cudaGraphicsResource* rc;
    cudaGraphicsGLRegisterBuffer(&rc, *r->ssbo, cudaGraphicsMapFlagsWriteDiscard);
    cudaGraphicsMapResources(1, &rc, 0);
    size_t num_bytes;
    cudaGraphicsResourceGetMappedPointer((void**)&output, &num_bytes, rc);
    cudaError err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(err));
        throw;
    }
    *r = { rc, r->ssbo };
    return r;
}


void renderScene(scene s, GLFWwindow* window, Buffer* buff, int n) {
    glUseProgram(*s.compute);
    cudaGraphicsUnmapResources(1, &s.r->cr, 0);
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(err));
        throw;
    }
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, *(s.r->ssbo));
    glUniform1f(glGetUniformLocation(*s.compute, "w"), vx);
    glDispatchCompute(NX, NY, 1);
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
    processInput(window);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(*s.vertex);
    glBindVertexArray(buff->VAO); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, *s.texture);
    glDrawElements(GL_TRIANGLES, 6 * n / sizeof(float), GL_UNSIGNED_INT, (void*)0);
    glfwSwapBuffers(window);
    glfwPollEvents();
    cudaGraphicsMapResources(1, &s.r->cr, 0);
    size_t num_bytes;
    cudaGraphicsResourceGetMappedPointer((void**)&output, &num_bytes, s.r->cr);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(err));
        throw;
    }
}

GLFWwindow* init_OpenGL(Log& log) {
    log.new_state("GLFW");
    log.log_state("GLFW_VERSION 4.6");
    log.log_state("SCR_WIDTH "  + std::to_string(SCR_WIDTH));
    log.log_state("SCR_HEIGHT " + std::to_string(SCR_HEIGHT));
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LBM", NULL, NULL);
    glfwMakeContextCurrent(window);
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        log.log_state("Failed to initialize OpenGL");
        throw std::runtime_error("Runtime Error");
    }
    return window;
}
GLFWwindow* init_OpenGL(int x, int y, const char* name) {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    GLFWwindow* window = glfwCreateWindow(x, y, name, NULL, NULL);
    glfwMakeContextCurrent(window);
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        throw std::runtime_error("Runtime Error");
    }
    return window;
}