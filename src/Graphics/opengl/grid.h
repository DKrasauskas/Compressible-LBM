#pragma once

struct Grid {
    float* vertices;
    uint* indices;
    uint v_size, i_size;
    ~Grid() {
        free(vertices);
    }
};

Grid grid(int n) {
    float* vertices = (float*)malloc(sizeof(float) * (n) * (n) * 3);
    uint* indices = (uint*)malloc(sizeof(uint) * (n - 1) * (n - 1) * 6);
    if (vertices == NULL) throw;
    float dt = 1.0f / (n - 1);
    int index = 0;
    int ind = 0;
    int ind_index = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            vertices[index] = -0.5f + dt * j;
            vertices[index + 1] = -0.5f + dt * i;
            vertices[index + 2] = 0.0f;
            index += 3;
        }
    }
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - 1; j++) {
            indices[ind] = j + i * n;
            indices[ind + 1] = j + 1 + i * n;
            indices[ind + 2] = j + 1 + (i + 1) * n;
            indices[ind + 3] = j + i * n;
            indices[ind + 4] = j + (i + 1) * n;
            indices[ind + 5] = j + 1 + (i + 1) * n;
            ind += 6;
        }
    }
    return { vertices, indices,  (uint)((n) * (n) * 3 * sizeof(float)), (uint)((n - 1) * (n - 1) * 6 * sizeof(uint)) };
}