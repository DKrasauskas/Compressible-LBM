#pragma once


struct Stress {
	float dudx, dudy, dvdx, dvdy;

	__device__
	Stress(vec2* u) {
		this->dudx = (u[2].x - u[1].x) / (2.0f * del_x);
		this->dvdy = (u[4].y - u[3].y) / (2.0f * del_y);
		this->dvdx = (u[2].y - u[1].y) / (2.0f * del_x);
		this->dudy = (u[4].x - u[3].x) / (2.0f * del_y);
	}
};