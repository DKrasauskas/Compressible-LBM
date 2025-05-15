//
// Created by domin on 09/05/2025.
//

#include "../Graphics/imgui/Plot.h"



Plot::Plot(const char* name, int x, int y) {
    this->plotX = (float*)malloc(sizeof(float) * x);
    this->plotY = (float*)malloc(sizeof(float) * y);
    this->mem_init = true;
    for (int i = 0; i < x; i++) {
        this->plotX[i] = i;
        this->plotY[i] = 0;
    }
    this->name = name;
}

Plot::Plot() {
    this->active = false;
    this->mem_init = false;
    this->x = 800;
    this->y = 800;
}

Plot::Plot(const Plot &rhs) {
    this->plotX = (float*)malloc(sizeof(float) * x);
    this->plotY = (float*)malloc(sizeof(float) * y);
    this->mem_init = true;
    this->name =rhs.name;
    memcpy(plotX, rhs.plotX, sizeof(float) * x);
    memcpy(plotY, rhs.plotY, sizeof(float) * y);
}

Plot& Plot::operator=(const Plot& other){
    if(this == & other) return * this;
    this->x = other.x;
    this->y = other.y;
    this->plotX = (float*)malloc(sizeof(float) * x);
    this->plotY = (float*)malloc(sizeof(float) * y);
    this->mem_init = true;
    this->autofit = other.autofit;
    this->active = other.active;
    memcpy(this->plotX, other.plotX, sizeof(float ) * other.x);
    memcpy(this->plotY, other.plotY, sizeof(float ) * other.y);
    return *this;
}

Plot::~Plot() {
    if(this->mem_init){
        free(plotX);
        free(plotY);
        this->mem_init = false;
    }
}

void Plot::RenderPlot(int n, const char* name) {
    ImPlot::SetNextAxesToFit();
    if (ImPlot::BeginPlot(name)) {
        if(!active){
            ImPlotRect limits = ImPlot::GetPlotLimits();
            min_lim = limits.X;
            max_lim = limits.Y;
            active = !active;
        }
        ImPlot::PlotLine(name, plotX, plotY, n);
        ImPlot::EndPlot();

    }
}
/*___________________________________MENU______________________________________*/

Menu::Menu(GLFWwindow* window, int x, int y) {
    setup_plotting(window);
    this->n = 400;
    this->autofit = false;
    plots = (Plot*)malloc(sizeof(Plot) * 10);
    active = (bool*)calloc(10, sizeof(bool));
    this->mem_init = true;
}
Menu::~Menu() {
    if(this->mem_init){
        free(plots);
        free(active);
        this->mem_init = false;
    }
}


void Menu::setup_plotting(GLFWwindow* window) {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsDark();

    // Setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");
    ImPlot::CreateContext();
}

void Menu::ShowSettingsWindow() {
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::Begin("SETTINGS");

    // Display settings
    ImGui::Text("DISPLAY");
    ImGui::Checkbox("relaxation", &rel);
    if (rel) {
        ImGui::SliderFloat("Light Intensity", &tau, 0.0f, 2.0f);
    }
    ImGui::Separator();
    ImGui::Checkbox("Density", &rho);
    ImGui::Checkbox("Pressure", &p);
    ImGui::Separator();
    ImGui::Checkbox("Simulate", &simulation_state);
    ImGui::End();
}



void Menu::render_menu(GLFWwindow* window, Domain* d) {
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    glfwMakeContextCurrent(window);
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // Create a window for plotting
    ShowSettingsWindow();

    if (rho) {
        //transfer data from the solver to the plotter
        //cudaMemcpy(this->plots[0].plotY, this->d->rho + 200 * 400, sizeof(float) * this->n, cudaMemcpyDeviceToHost);
        ImGui::Begin("Density");
        if (!active[0]) {
            active[0] = !active[0];
            plots[0] = Plot("Density");
        }
        upload_data((void*)(plots[0].plotY), (void*)(d->rho + 400), 400 * sizeof(float));
        plots[0].RenderPlot(400, "Density");
        ImGui::End();
    }else{
        if (active[0]){
            //plots[0].~Plot();
            active[0] = !active[0];
        }
    }
    // Rendering
    ImGui::Render();
    glClearColor(0.0f, 0.0f, 0.0f, 1.00f);
    glClear(GL_COLOR_BUFFER_BIT);

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(window);
    glfwPollEvents();
}

void Menu::upload_data(void *dest, void *src, unsigned int size) {
    cudaMemcpy(dest, src, size, cudaMemcpyDeviceToHost);
}