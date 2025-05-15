cmake_minimum_required(VERSION 3.26)
project(LBM LANGUAGES C CXX CUDA)

set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)


include_directories(
        ${CMAKE_SOURCE_DIR}/include/KHR
        ${CMAKE_SOURCE_DIR}/include/GLFW
        ${CMAKE_SOURCE_DIR}/include/glad/include/glad
        C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.5/include
)
set(SOURCES
        main.cu
        include/glad/src/glad.c
)
set_source_files_properties(
        include/glad/src/glad.c
        src/src/log.cu
        src/src/Device.cu
        src/src/Plot.cu
        src/src/dataset.cu
        PROPERTIES LANGUAGE CUDA)


find_package(CUDA REQUIRED)

link_directories(
        C:/Users/domin/CLionProjects/LBM/lib
        $(WindowsSDK_LibraryPath_x64)
)

add_executable(LBM
        src/src/setup.cu
        main.cu
        include/glad/src/glad.c
        src/src/Shader.cu
        src/src/buffer.cu
        include/imgui-master/imgui.cpp
        include/imgui-master/imgui_draw.cpp
        include/imgui-master/imgui_widgets.cpp
        include/imgui-master/imgui_tables.cpp
        include/implot-master/implot.cpp
        include/implot-master/implot_items.cpp
        include/imgui-master/backends/imgui_impl_glfw.cpp
        include/imgui-master/backends/imgui_impl_opengl3.cpp
        src/src/log.cu
        src/src/Device.cu
        src/src/Plot.cu
        src/src/dataset.cu
)


target_link_libraries(LBM PRIVATE
        glfw3
        opengl32
)

set_target_properties(LBM PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)
