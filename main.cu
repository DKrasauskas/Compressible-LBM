#define uint unsigned int

#include <glad.h>
#include <glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cuda_gl_interop.h>

#include "src/settings/log.h"
Log program_log;


#include "src/settings/setup.cuh"
#include "src/Graphics/opengl/grid.h"
#include "src/Graphics/opengl/Shader.h"
#include "src/Graphics/opengl/buffer.h"


#include "include/imgui-master/imgui.h"
#include "include/imgui-master/backends/imgui_impl_opengl3.h"
#include "include/imgui-master/backends/imgui_impl_glfw.h"
#include "include/implot-master/implot.h"

#include "src/Physics/process.cuh"
#include "src/Graphics/opengl/controls.h"
#include "src/Graphics/opengl/opengl_context.h"

#include "src/Physics/GPU-code/physics.cuh"
#include "src/Physics/Device.cuh"
#include "src/Graphics/imgui/Plot.h"
#include "src/Physics/dataset.cuh"

__device__ Domain* D;


int main()
{
    program_log.output_path = "log.txt";
    program_log.begin();
    Device main_dev = Device(0);
    main_dev.info(program_log);
    GLFWwindow* window = init_OpenGL(program_log);
    GLFWwindow* plotting = init_OpenGL(1000, 500, "plot");
    glfwMakeContextCurrent(window);
    Shader vertex("../src/Graphics/opengl/GLSL/vertex.glsl", "../src/Graphics/opengl/GLSL/fragment.glsl", program_log);
    Shader compute("../src/Graphics/opengl/GLSL/compute.glsl", program_log);
    Grid gd = grid(2);
    Buffer buff((void*)gd.vertices, (void*)gd.indices, gd.v_size, gd.i_size);
    scene s = { &compute.ID, &vertex.ID, make_texture(), make_buffer() };
    Menu p(plotting);

    //LBM initialization
   // DatasetFP32(10000, 20000, program_log);
   // return 0;
   Domain* host = LBM::begin(&D);

    state = 2;
    int counter = 0;
    LBM::initial_conditions(&D, &host);
    while (!glfwWindowShouldClose(window) && !glfwWindowShouldClose(plotting))
    {
        if (counter > 1   && counter % 1  == 0){

            glfwMakeContextCurrent(window);
            renderScene(s, window, &buff, gd.v_size);
            gradient <<<blockH, threadH >>> (D, output, host->mask, NX, map_scale, state);
            cudaDeviceSynchronize();
            // cudaMemcpy(data, host->rho + 200 * 400, sizeof(float) * 400, cudaMemcpyDeviceToHost);
            p.render_menu(plotting, host);
            if (p.rho && p.active[0]) {
               // upload_plot(host->rho + 200 * 400, p.plots[0].plotY, 400);

            }
            if(p.simulation_state)LBM::job(&D, &host, counter, counter);

        }
        else {
            std::cout << counter << "\n";
            //renderScene(s, window, &buff, gd.v_size);
            LBM::job(&D, &host, counter, counter);
        }
        counter++;

    }
    program_log.end();
    return 0;
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}


