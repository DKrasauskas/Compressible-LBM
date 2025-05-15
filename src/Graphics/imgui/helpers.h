#pragma once
/*
 *
 *
 * THIS FILE HAS BEEN SUPERSEDED BY Plot.h class
 *
 *
 *
 */

struct menu_output {
    bool simulation_state = false; // controls whether to run LBM or not
    float tau;
    float* plotY, * plotX;
    int n;
    bool rho, p, rel;
};



void RenderPlot(float* x, float* y, int n, const char* name) {
    ImPlot::SetNextAxesToFit();
    if (ImPlot::BeginPlot(name)) {
        // Plot a line
        ImPlot::PlotLine("Sine", x, y, n);
        ImPlot::EndPlot();
    }
}

void setup_plotting(GLFWwindow* window) {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsDark();

    // Setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");
    ImPlot::CreateContext();
}

void ShowSettingsWindow(menu_output* output) {
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::Begin("SETTINGS");

    // Display settings
    ImGui::Text("DISPLAY");
    ImGui::Checkbox("relaxation", &output->rel);
    if (output->rel) {
        ImGui::SliderFloat("Light Intensity", &output->tau, 0.0f, 2.0f);
    }
    ImGui::Separator();
    ImGui::Checkbox("Density", &output->rho);
    ImGui::Checkbox("Pressure", &output->p);
    ImGui::Separator();
    ImGui::Checkbox("Simulate", &output->simulation_state);
    ImGui::End();
}
void render_menu(GLFWwindow* window, menu_output* out) {
    glfwMakeContextCurrent(window);
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // Create a window for plotting            
    ShowSettingsWindow(out);

    if (out->rho) {
        ImGui::Begin("Density");
        RenderPlot(out->plotX, out->plotY, out->n, "Density");  // Call the plot rendering function
        ImGui::End();
    }
    if (out->p) {
        ImGui::Begin("Pressure");
        RenderPlot(out->plotX, out->plotY, out->n, "Pressure");  // Call the plot rendering function
        ImGui::End();
    }

    // Rendering
    ImGui::Render();
    glClearColor(0.0f, 0.0f, 0.0f, 1.00f);
    glClear(GL_COLOR_BUFFER_BIT);

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(window);
    glfwPollEvents();
}

void upload_plot(float* src, float* dest, int count) {
    cudaMemcpy(dest, src, sizeof(float) * count, cudaMemcpyDeviceToHost);
}