#pragma once
#include <cuda_runtime.h>
//atmo
#define P0 1E5f
#define T_0 287.0f
#define Rgas 287.0f 
#define R0 8.314f
#define rho0 1.29f //kg/m^3
#define gamma 1.4f
#define miu 1.81E-5

//thermal conductivity
#define lambda_T 0.0f
//computed properties
#define C_v (3.0f / 2.0f * Rgas)
#define C_p (C_v * gamma)



/*_____________________________________________________LBM PROPERTIES_____________________________________________________________*/
//length of grid
#define LX 10
#define LY 10

#define rhol 0.02766f
#define pl 0.0065857f

#define del_x (.1f) 
#define del_y (.1f) 
#define del_t .02f

#define tref 1.0f

#define cs 0.57735026918962576450914878050196f
#define sigma 1.0f
#define Tref
#define rref 287.15 //Km2s-2
#define C0 1.f

#define vl (del_x / del_t)
 


#define tau_	1.5f
#define k (0.4f)


#define c_real  329.4345f
