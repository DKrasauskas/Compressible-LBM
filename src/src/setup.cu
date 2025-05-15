#pragma once
#include "../settings/setup.cuh"


//exec
dim3 blockH(20, 20);
dim3 threadH(20, 20);
dim3 block1(48000, 1);
dim3 thread1(64, 1);


float** fhost;
float** host_buff;
float* output;
float map_scale = 1.0f;

float vx = -0.3f;
float yc = 0.0f;
int state = 0;
vec2 es[9] = {
        { 0,  0},
        { 1,  0},
        { 0,  1},
        {-1,  0},
        { 0, -1},
        { 1,  1},
        {-1,  1},
        {-1, -1},
        { 1, -1},
};
float weights[9] = {
        (float)4 / 9,
        (float)1 / 9, (float)1 / 9, (float)1 / 9, (float)1 / 9,
        (float)1 / 36, (float)1 / 36, (float)1 / 36, (float)1 / 36
};