#pragma once
void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        vx += 0.1f;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        vx -= 0.1f;
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        map_scale *= 1.1;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        map_scale /= 1.1;
    if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS)
        state = 0;
    if (glfwGetKey(window, GLFW_KEY_T) == GLFW_PRESS)
        state = 1;
    if (glfwGetKey(window, GLFW_KEY_Y) == GLFW_PRESS)
        state = 2;
    if (glfwGetKey(window, GLFW_KEY_U) == GLFW_PRESS)
        state = 3;
    if (glfwGetKey(window, GLFW_KEY_I) == GLFW_PRESS)
        state = 4;
    if (glfwGetKey(window, GLFW_KEY_O) == GLFW_PRESS)
        state = 5;
    if (glfwGetKey(window, GLFW_KEY_P) == GLFW_PRESS)
        state = 6;
}
// allocates variables and sets up initial conditions

