//
// Created by domin on 09/05/2025.
//


#pragma once
#include "../../../include/implot-master/implot.h"
#include "glfw3.h"
#include "../../../include/imgui-master/imgui.h"
#include "../../../include/imgui-master/backends/imgui_impl_opengl3.h"
#include "../../../include/imgui-master/backends/imgui_impl_glfw.h"
#include "../../../include/implot-master/implot.h"
#include "../../Physics/LBM/Domain.cuh"
#include <malloc.h>
#include <cuda_runtime.h>



class Plot{
public:
    float* plotY, * plotX;
    bool active = false;
    bool autofit = false;
    bool mem_init = false;
    const char* name;
    int x = 800;
    int y = 800;
    ImPlotRange min_lim, max_lim;
    void RenderPlot(int n, const char* name);
    Plot(const char* name, int x = 800, int y = 800);
    ~Plot();
    Plot(const Plot& rhs);
    Plot();
    Plot& operator=(const Plot& other);
};

class Menu {
public:
    bool simulation_state = false; // controls whether to run LBM or not
    float tau;
    int n;
    bool rho = false;
    bool p = false;
    bool rel;
    bool autofit = false;
    bool mem_init = false;
    bool* active;
    Plot* plots;
    //Domain* d;
    explicit Menu(GLFWwindow* window, int x = 800, int y = 800);
    ~Menu();
    void setup_plotting(GLFWwindow* window);
    void ShowSettingsWindow();
    void render_menu(GLFWwindow* window, Domain* d);
    void upload_data(void* dest, void* src, unsigned int size);
};

