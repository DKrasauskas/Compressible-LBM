#pragma once
#define cs2 0.33333333333333333333333333333f

__device__ __host__ long double H_aa(long double c1, long double c2) {
	return c1 * c2 - cs * cs;
}
__device__ __host__ long double H_ab(long double c1, long double c2) {
	return c1 * c2;
}
__device__  __host__ long double H_aaa(long double c1) {
	return c1 * (c1 * c1 - cs * cs * 3);
}
__device__ __host__ long double H_baa(long double b, long double a) {
	return b * (a * a - cs * cs) ;
}
__device__ __host__ long double H_bbaa(long double b, long double a) {
	return a * a * b * b - cs * cs * (a * a + b * b) + cs * cs * cs * cs;
}
__device__ __host__ long double A_aa(long double a, long double b, long double C) {
	return a * a + C;
}
__device__ __host__ long double A_ab(long double a, long double b, long double C) {
	return a * b;
}
__device__ __host__ long double A_aaa(long double a, long double b, long double C) {
	return a * (a * a + C * 3);
}
__device__ __host__ long double A_baa(long double a, long double b, long double C) {
	return b * (a * a + C);
}
__device__ __host__ long double A_bbaa(long double a, long double b, long double C) {
	return a * a * b * b + C * C * +C * (a * a + b * b);
}


// 0    1   2    3   4    5     6    7     8
// H0, HX, HY, HXX, HXY, HYY, HXXY, HYYX, HXXYY

float** hermite_Polynomials(vec2* e) {
	float** pol = (float**)malloc(sizeof(float*) * 9);
	for (int i = 0; i < 9; i++) {
		pol[i] = (float*)malloc(sizeof(float) * 11);
		pol[i][0] = 1.0f;
		pol[i][1] = (long double)e[i].x;	
		pol[i][2] = (long double)e[i].y;
		pol[i][3] =  H_aa(e[i].x , e[i].x ); //HXX
		pol[i][4] =  H_ab(e[i].x , e[i].y ); //HXY
		pol[i][5] =  H_aa(e[i].y , e[i].y ); //HYY
		pol[i][6] =  H_baa(e[i].y , e[i].x ); //Hyxx
		pol[i][7] =  H_baa(e[i].x , e[i].y ); //Hxyy
		pol[i][8] =  H_bbaa(e[i].x, e[i].y );
		pol[i][9] =  H_aaa(e[i].x);
		pol[i][10] = H_aaa(e[i].y);
	}
	return pol;
}