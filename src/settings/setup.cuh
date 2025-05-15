#ifndef SETUP_H  // Check if HEADER_H has not been defined
#define SETUP_H  // Define HEADER_H to prevent multiple inclusions
//openGL
const unsigned int SCR_WIDTH = 1024;
const unsigned int SCR_HEIGHT = 1024;
//simulation parameters

#define NX  400
#define NY  400
#define SKIP_ITTER 2

#define csoi 0.57735026919f

#define max_v 0.1f
#define heatmap_velocity 300
#define heatmap_curl 50
#define show_airfoil 0



//exec 
extern dim3 blockH;
extern dim3 threadH;
extern dim3 block1;
extern dim3 thread1;

struct vec2 {
    float x, y;
};
struct vec2INT {
    int x, y;
};


__device__ extern bool* mask, *maskDEV;

extern float** fhost, ** host_buff;

extern float map_scale;
extern float* output;
extern float vx ;
extern float yc;
extern float* buffs;
extern int state;

extern vec2 es[9];

extern float weights[9];
#endif