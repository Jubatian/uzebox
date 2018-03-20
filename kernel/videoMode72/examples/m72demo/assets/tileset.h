/*  GIMP header image file format (INDEXED): /home/pettyes/uzebox/my_devel/tutor_test/dragon/assets/tiles.h  */

static unsigned int width = 1536;
static unsigned int height = 8;

/*  Call this macro repeatedly.  After each use, the pixel data can be extracted  */

#define HEADER_PIXEL(data,pixel) {\
pixel[0] = header_data_cmap[(unsigned char)data[0]][0]; \
pixel[1] = header_data_cmap[(unsigned char)data[0]][1]; \
pixel[2] = header_data_cmap[(unsigned char)data[0]][2]; \
data ++; }

static char header_data_cmap[256][3] = {
	{146,219,255},
	{109,146,255},
	{ 36, 73,170},
	{  0,  0,  0},
	{ 36, 36,  0},
	{ 36, 73,  0},
	{ 36,109,  0},
	{109,146,  0},
	{182, 73,  0},
	{109, 36,  0},
	{ 73, 73, 85},
	{109,109, 85},
	{146,146,170},
	{182,182,170},
	{219,219, 85},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255}
	};
static char header_data[] = {
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,7,0,6,6,7,6,6,7,6,6,6,
	6,6,6,6,6,7,6,6,6,0,7,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,6,6,6,6,6,7,6,6,
	6,7,6,6,7,6,6,6,6,6,7,6,6,7,6,6,
	11,4,3,10,11,4,3,3,11,10,3,10,11,4,10,10,
	0,0,0,0,13,7,7,7,7,6,5,6,7,6,6,5,
	11,6,10,10,5,6,4,5,0,0,0,0,0,0,0,0,
	0,0,0,0,0,13,7,0,7,7,0,0,0,0,0,0,
	0,0,0,7,7,6,5,6,7,11,7,7,13,6,6,7,
	6,7,5,7,5,0,6,0,6,0,7,0,0,0,0,0,
	0,0,0,0,13,7,7,7,7,6,5,6,7,6,6,5,
	11,6,10,10,5,6,4,5,0,0,0,0,11,11,10,4,
	11,10,4,10,11,4,3,3,11,10,3,10,11,4,10,11,
	0,0,0,0,11,0,11,11,11,0,0,0,0,0,0,0,
	11,10,4,10,11,4,10,10,11,10,3,10,11,10,10,11,
	0,11,10,4,3,3,4,3,4,4,3,4,3,10,11,0,
	0,0,0,0,0,0,11,11,11,11,0,0,0,0,0,0,
	11,4,3,4,3,3,4,3,4,4,3,4,3,10,10,0,
	4,4,3,4,3,3,4,3,4,4,3,4,3,3,4,3,
	3,4,4,3,3,3,3,4,4,4,3,3,3,10,10,11,
	10,11,11,10,10,11,11,11,11,10,10,11,11,10,11,11,
	11,11,3,3,3,3,4,4,3,3,3,4,3,3,3,4,
	0,0,0,0,0,0,0,0,0,0,15,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,2,2,2,2,2,1,1,1,2,2,2,2,
	11,11,11,10,3,3,3,4,3,3,10,11,10,4,3,3,
	4,10,11,10,10,4,3,3,4,4,3,3,11,3,4,3,
	3,3,11,10,4,10,3,3,15,15,13,0,0,15,15,15,
	15,15,13,0,0,15,15,15,15,15,13,0,0,15,15,13,
	14,15,15,15,14,15,15,13,14,15,15,15,14,15,15,13,
	14,15,15,15,14,15,15,13,15,15,15,15,15,15,15,13,
	15,13,15,13,12,11,12,11,15,13,15,13,13,11,11,11,
	13,13,12,13,12,13,12,10,13,13,13,12,12,13,12,11,
	13,13,12,13,12,13,12,11,13,13,12,13,12,13,12,11,
	13,10,0,0,0,0,13,11,14,15,14,15,15,15,15,13,
	11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
	11,11,11,11,11,11,11,11,4,11,10,4,10,11,4,10,
	3,3,4,10,11,4,10,10,11,10,3,10,11,4,3,3,
	13,13,12,13,12,13,12,11,4,4,4,4,4,4,4,3,
	10,4,4,4,4,4,4,3,4,4,4,3,10,4,4,4,
	11,10,10,4,11,10,11,10,11,11,10,10,11,10,10,4,
	11,11,10,10,11,10,10,4,4,4,4,4,4,4,4,4,
	4,10,10,10,3,10,3,4,3,4,4,4,4,4,4,4,
	4,10,10,4,4,10,4,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	13,13,12,13,12,13,12,11,13,13,12,13,12,13,12,11,
	13,13,12,13,12,13,12,11,13,13,12,13,12,13,12,11,
	13,8,14,14,8,13,12,11,13,8,14,8,14,13,12,11,
	13,13,8,14,8,13,12,11,13,8,8,14,14,13,12,11,
	4,4,4,10,4,4,4,3,4,4,4,10,4,4,4,3,
	4,4,4,4,4,4,4,3,4,4,4,10,4,4,4,3,
	4,8,14,14,14,4,4,3,4,8,13,14,8,4,4,3,
	4,4,8,14,8,4,4,3,4,8,8,13,13,8,4,3,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,7,0,6,7,6,7,6,7,7,6,7,6,7,6,
	6,6,7,5,6,6,7,11,7,6,7,6,0,7,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,6,6,7,5,6,6,5,6,
	6,7,7,6,7,6,7,6,6,5,6,5,6,6,7,11,
	11,4,3,3,11,10,3,4,10,11,10,10,10,11,10,4,
	0,0,0,13,0,7,6,6,7,6,5,7,5,5,5,6,
	5,10,6,5,5,5,5,5,0,0,0,0,0,0,0,0,
	0,0,7,0,0,13,7,6,6,0,7,0,0,0,0,0,
	0,0,7,13,6,6,6,7,6,7,6,5,11,6,5,6,
	5,6,7,6,5,6,6,7,7,6,6,6,6,0,0,0,
	0,0,0,0,0,7,6,6,7,6,5,7,5,5,5,6,
	5,10,6,5,5,5,5,5,0,0,0,0,11,10,4,10,
	11,11,4,4,11,10,3,4,10,11,10,10,10,11,11,0,
	0,0,0,11,10,11,10,4,11,0,0,0,0,0,0,0,
	11,11,10,10,10,11,10,4,10,11,10,10,10,11,11,0,
	11,10,4,3,4,10,3,3,10,3,3,3,10,11,0,0,
	0,0,0,0,0,11,10,4,10,10,11,0,0,11,0,0,
	11,4,3,3,4,10,3,3,10,3,3,3,4,10,0,0,
	4,3,3,3,4,4,3,3,10,3,3,3,4,10,3,3,
	3,3,4,4,3,3,4,3,3,3,4,10,11,11,11,10,
	11,11,10,11,11,10,10,10,10,11,11,10,10,11,11,4,
	11,10,11,10,3,4,4,3,3,3,3,3,4,4,4,4,
	0,0,0,0,0,0,0,0,0,15,14,15,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,
	10,11,10,11,4,3,4,4,3,3,10,11,4,4,3,3,
	4,10,11,11,10,4,4,3,4,3,3,3,11,3,3,3,
	3,3,11,10,10,4,3,3,15,13,11,0,0,15,14,13,
	13,13,11,0,0,15,14,13,13,13,11,0,0,15,13,11,
	15,13,14,13,13,13,13,11,15,13,14,13,13,13,13,11,
	15,13,14,13,13,13,13,11,15,14,13,14,13,13,13,11,
	15,13,15,14,13,11,12,11,15,13,15,14,12,11,12,11,
	13,12,12,12,12,12,12,11,13,12,12,12,12,12,12,11,
	13,12,12,12,12,12,12,11,13,12,11,10,10,11,12,11,
	13,10,0,0,0,0,12,11,15,14,13,13,14,13,14,11,
	14,13,14,13,14,13,14,11,14,11,13,11,14,11,13,11,
	14,11,14,11,14,11,14,11,11,10,4,11,3,4,10,3,
	3,4,10,10,10,11,10,4,10,11,10,11,10,11,3,4,
	13,12,12,12,12,12,12,11,4,4,4,4,4,4,4,3,
	4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,4,
	10,10,10,4,11,10,10,10,11,10,10,10,10,10,10,4,
	11,10,10,10,10,10,10,4,4,3,3,3,3,3,3,4,
	4,10,3,10,3,10,3,4,4,3,3,3,3,3,3,4,
	4,4,4,4,4,10,4,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	13,12,12,12,12,12,12,11,13,12,12,12,8,12,12,11,
	13,12,12,12,12,12,12,11,13,12,12,8,12,12,12,11,
	13,12,8,14,8,12,12,11,13,12,13,14,12,12,12,11,
	13,12,13,14,13,12,12,11,13,12,13,14,8,12,12,11,
	4,4,4,4,10,4,4,3,4,4,4,4,10,4,4,3,
	4,4,4,4,10,4,4,3,4,4,4,4,10,4,4,3,
	4,4,8,14,8,4,10,3,4,4,8,14,11,4,10,3,
	4,4,11,14,11,4,10,3,4,4,11,14,8,4,10,3,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	7,0,7,6,7,6,5,7,6,6,7,5,6,6,6,5,
	7,6,7,6,6,5,7,6,7,5,6,7,6,7,0,7,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,7,6,7,6,6,11,10,5,
	6,6,7,5,5,6,11,5,5,6,6,6,6,5,7,6,
	11,10,3,3,11,11,4,3,3,10,11,4,4,11,4,3,
	0,0,0,0,7,7,6,5,6,5,7,6,7,5,4,5,
	5,6,5,6,6,0,5,0,0,0,0,0,0,0,0,0,
	7,13,7,13,7,0,13,7,6,6,7,0,0,0,0,0,
	0,0,7,13,6,6,7,13,6,5,7,5,5,7,6,5,
	5,7,6,5,6,5,5,7,6,5,5,6,0,0,0,0,
	0,0,0,0,0,0,6,5,6,5,6,7,7,5,4,5,
	5,6,5,6,6,0,5,0,0,0,0,0,11,10,10,0,
	0,11,10,4,11,11,4,3,3,10,11,4,4,11,0,0,
	0,0,11,10,10,11,4,4,11,11,0,0,11,11,0,0,
	0,11,11,4,4,11,4,3,3,10,11,4,4,11,0,0,
	11,10,4,4,4,3,4,3,10,3,3,4,10,11,0,0,
	0,0,0,11,11,10,10,3,10,4,4,10,11,10,11,0,
	11,10,3,4,4,3,4,3,10,3,3,4,4,10,11,0,
	4,3,3,4,4,3,4,3,10,3,3,4,4,3,4,3,
	3,4,4,3,4,4,4,3,3,10,11,11,4,11,4,3,
	11,10,3,3,11,10,4,3,3,10,11,4,4,11,4,3,
	11,10,10,11,11,10,4,3,3,3,3,3,4,3,4,3,
	0,0,0,0,0,0,0,0,15,14,15,15,15,0,0,0,
	0,0,0,15,15,0,0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,1,1,2,2,2,2,2,2,2,2,2,2,
	4,11,11,10,10,4,4,3,3,3,4,11,10,4,3,3,
	4,11,11,10,4,10,3,3,4,3,3,10,11,3,4,3,
	3,3,11,11,4,10,3,3,15,13,11,0,0,15,13,13,
	13,12,11,0,0,15,13,13,13,12,11,0,0,15,13,11,
	15,13,13,13,13,13,13,11,15,13,13,13,13,13,13,11,
	15,13,13,13,13,13,12,11,15,13,13,13,13,13,13,11,
	15,14,15,13,13,11,11,10,15,14,15,13,13,11,12,10,
	13,12,12,12,12,12,11,10,12,12,12,12,12,12,12,10,
	12,12,12,12,12,12,11,10,12,11,10,0,0,10,11,11,
	12,12,13,13,13,13,13,11,14,13,13,13,13,13,12,11,
	11,11,11,11,11,11,11,11,13,11,14,11,13,11,14,11,
	13,11,13,11,13,11,13,11,11,3,11,4,4,4,11,4,
	3,3,11,4,4,11,4,3,3,10,11,4,4,10,10,3,
	12,12,14,14,14,12,11,10,4,4,11,11,11,4,3,3,
	4,4,4,4,4,4,3,3,4,4,4,3,4,4,4,4,
	10,10,10,3,10,10,10,10,10,10,10,10,10,10,10,4,
	10,10,10,10,10,10,10,4,4,10,10,10,10,10,10,4,
	4,10,3,10,3,10,3,4,4,4,4,4,4,4,4,4,
	4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	12,12,12,12,8,12,11,10,12,12,12,8,12,12,11,10,
	12,12,12,8,12,12,11,10,12,12,12,13,8,12,11,10,
	12,12,14,14,14,12,11,10,12,12,14,14,14,12,11,10,
	12,12,14,14,14,12,11,10,12,12,14,14,14,12,11,10,
	4,4,10,4,4,4,3,3,4,4,4,8,4,4,3,3,
	4,4,8,4,4,4,3,3,4,4,10,8,4,4,3,3,
	4,4,12,13,12,4,3,3,4,4,12,13,12,4,3,3,
	4,4,12,13,12,4,3,3,4,4,12,13,12,4,3,3,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,
	6,6,7,6,6,7,6,6,7,5,6,6,6,7,6,6,
	7,5,6,11,7,6,6,6,6,6,7,6,6,7,6,6,
	7,0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,
	0,0,0,0,0,0,0,0,7,5,6,11,11,10,10,3,
	10,6,6,5,10,11,5,4,3,5,11,5,7,6,6,6,
	10,11,4,10,10,11,10,4,3,4,11,3,3,10,10,3,
	0,0,0,7,0,6,7,5,5,5,6,5,6,5,11,5,
	6,5,5,6,5,5,0,5,0,0,0,0,0,0,0,0,
	7,7,7,6,6,6,7,7,7,5,6,0,13,7,0,0,
	0,0,7,6,0,5,13,7,5,5,6,6,7,11,6,11,
	5,11,6,5,6,5,6,6,5,6,6,5,0,0,0,0,
	0,0,0,0,0,6,0,5,5,5,6,7,6,5,11,5,
	6,5,5,6,5,5,0,0,0,0,0,0,11,11,4,0,
	0,11,10,10,10,11,10,4,3,4,11,3,4,10,0,0,
	0,0,11,10,4,10,10,3,10,11,0,11,10,11,0,0,
	0,0,11,10,4,10,10,3,3,4,11,3,3,10,10,0,
	0,11,10,4,3,3,10,4,4,10,3,4,4,10,11,0,
	0,0,11,10,4,4,10,4,4,10,3,4,4,4,10,0,
	11,10,4,10,3,4,10,4,4,10,3,4,3,4,10,11,
	4,4,3,4,3,3,4,4,4,10,3,4,3,3,10,4,
	4,4,3,3,3,3,10,10,11,11,11,3,3,10,10,3,
	10,11,4,10,10,11,10,4,3,4,11,3,3,10,10,3,
	10,11,4,10,10,11,10,11,10,4,3,3,4,3,3,3,
	0,0,15,15,15,0,0,0,15,14,13,15,15,15,15,0,
	0,0,15,15,15,15,0,0,0,0,0,0,0,0,0,0,
	1,1,2,2,2,2,2,1,1,1,1,2,2,2,2,2,
	3,10,11,11,10,10,4,3,3,4,4,10,11,4,3,4,
	4,11,11,10,10,4,4,4,4,4,3,11,10,4,3,4,
	3,3,11,10,10,4,3,3,13,11,11,0,0,13,11,11,
	11,11,11,0,0,13,11,11,11,11,11,0,0,14,11,11,
	13,11,11,11,11,11,11,11,13,11,11,11,11,11,11,11,
	13,11,11,11,11,11,11,11,13,11,11,11,11,11,11,10,
	13,13,13,11,11,11,10,10,13,13,13,11,11,11,11,11,
	11,11,11,10,11,11,10,4,10,11,11,11,11,11,11,4,
	11,11,11,10,11,11,11,4,10,10,0,0,0,0,11,10,
	11,10,11,10,11,11,10,10,11,11,11,11,11,11,10,10,
	14,11,13,11,14,11,13,11,14,11,13,11,14,11,14,11,
	14,11,13,11,14,11,13,11,4,10,3,11,11,10,3,11,
	3,4,11,3,3,10,10,3,3,11,10,3,3,10,11,3,
	11,11,13,14,13,11,11,4,3,3,3,11,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	4,4,3,3,4,4,4,3,4,4,3,3,4,4,4,3,
	4,4,3,3,4,4,4,3,3,10,3,10,3,10,3,3,
	3,10,3,10,3,10,3,3,3,4,3,3,3,3,4,3,
	3,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	11,11,11,8,12,11,11,4,11,11,8,8,12,11,11,4,
	11,11,12,8,8,11,11,4,11,11,8,12,8,11,11,4,
	11,11,13,14,13,11,11,4,11,11,13,14,13,11,11,4,
	11,11,13,14,13,11,11,4,11,11,13,14,13,11,11,4,
	3,3,3,8,4,3,3,3,3,3,8,4,4,3,3,3,
	3,3,3,8,4,3,3,3,3,3,8,4,4,3,3,3,
	3,4,3,11,3,3,4,3,3,4,3,11,3,3,4,3,
	3,4,3,11,3,3,4,3,3,4,3,11,3,3,4,3,
	0,0,0,0,0,0,0,0,0,0,0,0,7,6,0,6,
	6,6,6,5,6,7,6,7,7,6,6,7,6,7,6,7,
	6,6,5,6,7,6,5,7,7,6,7,6,5,6,6,6,
	6,0,6,7,0,0,0,0,7,0,7,0,0,7,7,0,
	0,0,0,0,0,0,0,0,6,6,5,10,3,4,11,4,
	10,5,11,5,3,11,11,4,4,4,11,10,5,6,5,7,
	10,10,4,10,3,11,11,4,4,4,11,10,3,4,11,4,
	0,0,0,0,7,0,6,5,6,5,5,6,10,7,5,5,
	10,5,6,5,5,7,5,0,0,0,0,0,0,0,0,7,
	0,7,6,7,5,0,7,6,6,6,0,7,7,6,6,0,
	0,0,7,6,6,0,7,5,0,6,7,13,7,6,7,5,
	11,5,5,6,7,6,5,5,5,0,6,0,0,0,0,0,
	0,0,0,0,0,0,6,0,6,5,5,5,10,5,5,5,
	10,5,6,0,5,4,5,0,0,7,0,11,11,10,5,0,
	0,0,11,10,4,11,11,4,4,4,11,10,4,10,11,0,
	0,0,11,10,4,4,11,4,10,10,10,10,4,11,11,0,
	0,0,11,10,4,4,11,4,4,10,11,10,4,4,11,0,
	0,0,11,4,3,3,3,10,3,3,10,3,3,10,10,11,
	0,0,11,4,4,3,3,10,3,3,10,3,3,4,10,11,
	0,11,10,10,4,4,10,10,3,3,10,3,4,10,10,11,
	3,3,4,3,3,3,3,4,3,3,10,3,3,3,3,10,
	3,3,4,3,3,10,11,11,4,4,11,10,3,4,11,4,
	10,10,4,10,3,11,11,4,4,4,11,10,3,4,11,4,
	10,10,4,10,3,11,11,4,10,11,10,4,4,4,3,3,
	0,15,15,15,15,15,15,15,14,15,14,14,14,13,13,15,
	15,0,13,15,15,15,15,15,15,15,15,15,0,0,0,0,
	2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,2,
	4,11,11,10,10,4,4,3,3,4,3,11,10,4,3,4,
	3,10,11,11,10,10,4,4,3,3,4,10,11,4,3,4,
	4,4,11,11,10,4,3,3,15,15,15,14,15,13,15,15,
	15,13,14,15,15,13,15,15,15,13,14,15,15,15,15,11,
	14,15,15,15,14,15,15,15,14,15,15,15,14,15,15,12,
	14,15,15,15,14,15,15,15,14,12,13,12,11,11,10,10,
	15,15,15,15,14,13,13,11,15,15,15,15,15,15,15,13,
	13,13,12,11,13,13,13,12,13,13,12,11,13,13,12,11,
	13,13,12,11,13,13,12,13,13,11,0,0,0,0,13,13,
	13,13,12,11,13,13,12,13,3,11,3,11,4,10,3,10,
	14,11,14,11,13,11,14,11,14,11,14,11,13,11,13,11,
	13,11,14,11,13,11,14,11,3,11,3,11,4,10,3,10,
	4,4,11,10,3,4,11,4,4,11,4,3,3,4,11,4,
	13,13,12,14,11,13,12,13,4,4,4,11,4,4,4,4,
	4,4,4,3,10,4,10,4,10,4,4,4,4,4,4,3,
	11,11,10,10,10,11,10,4,11,10,10,4,11,10,10,11,
	11,10,10,4,11,10,10,4,4,10,3,10,3,10,3,4,
	4,10,3,10,3,10,3,4,4,4,3,3,3,3,4,4,
	4,10,10,4,4,4,4,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	13,13,8,8,13,13,12,13,13,13,12,8,8,13,12,13,
	13,13,8,13,8,13,12,13,13,13,12,8,13,13,12,13,
	13,13,12,14,11,13,12,13,13,13,12,14,11,13,12,13,
	13,13,12,14,11,13,12,13,13,13,12,14,11,13,12,13,
	4,4,8,3,4,4,4,4,4,4,4,8,4,10,4,4,
	4,4,4,8,8,10,4,4,4,4,8,8,4,8,4,4,
	4,10,4,11,4,10,4,4,4,10,4,11,4,10,4,4,
	4,10,4,11,4,10,4,4,4,10,4,11,4,10,4,4,
	0,0,0,0,0,0,0,0,0,0,0,7,0,7,6,5,
	6,7,6,6,7,6,6,6,6,7,6,7,5,6,6,6,
	6,7,6,6,6,5,6,7,6,6,6,7,6,6,7,6,
	5,6,7,0,7,0,0,0,7,0,6,0,0,7,6,0,
	0,0,6,0,0,7,0,0,6,7,10,11,10,4,11,10,
	3,11,11,10,4,10,11,10,4,10,10,11,5,5,6,7,
	3,11,11,10,4,10,11,10,4,10,10,11,10,4,11,10,
	0,0,7,0,7,6,7,6,7,5,6,7,6,7,5,6,
	7,5,7,5,6,7,6,6,0,0,0,0,0,0,7,6,
	7,0,6,6,5,6,6,6,5,7,6,7,6,6,0,0,
	0,0,0,7,0,11,6,6,5,7,13,6,6,5,6,7,
	7,6,5,6,5,5,5,0,5,6,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,5,0,5,5,5,10,5,4,
	5,5,5,5,5,5,0,0,0,7,6,7,10,6,7,0,
	0,11,11,10,4,10,11,10,4,10,10,11,10,4,11,0,
	0,11,10,11,10,4,11,10,3,11,11,10,4,10,11,0,
	0,0,0,11,10,10,11,10,10,11,10,11,10,10,11,0,
	0,0,11,10,4,4,4,4,3,3,4,3,3,4,11,0,
	0,0,0,10,3,4,4,4,3,3,4,3,3,4,4,11,
	0,0,11,11,10,11,10,4,3,4,10,10,10,11,11,0,
	3,3,4,3,3,4,4,4,3,3,4,3,3,4,4,4,
	3,3,3,10,11,11,11,10,4,10,10,11,10,4,11,10,
	3,11,11,10,4,10,11,10,4,10,10,11,10,4,11,10,
	3,11,11,10,4,10,11,10,4,10,11,11,10,4,3,3,
	15,15,14,14,13,14,13,13,13,13,13,13,13,13,14,13,
	14,15,14,13,13,14,13,13,13,14,13,14,15,15,15,15,
	2,2,1,1,1,2,2,2,2,2,2,2,2,2,2,2,
	3,11,11,10,4,10,3,3,4,4,3,10,11,3,3,3,
	3,11,11,10,10,4,4,4,3,3,4,11,10,4,3,4,
	4,3,11,10,4,10,3,4,15,14,13,13,13,11,15,14,
	13,11,15,13,13,11,15,14,13,11,15,14,13,13,13,11,
	15,14,13,11,15,13,14,13,13,13,13,11,15,14,13,11,
	13,13,13,11,15,14,13,13,15,14,15,13,12,11,11,10,
	15,14,15,13,13,11,12,11,15,13,13,13,13,13,13,11,
	13,12,12,11,13,12,12,12,12,12,12,11,12,12,12,11,
	12,12,12,11,13,12,12,12,12,10,0,0,0,0,13,12,
	12,12,12,11,13,12,12,12,10,11,4,10,3,11,11,3,
	14,11,13,11,14,11,14,11,13,11,13,11,14,11,14,11,
	14,11,14,11,14,11,13,11,10,11,4,10,3,11,11,3,
	4,10,10,11,10,10,11,10,10,10,11,10,4,4,11,10,
	12,12,12,14,11,12,12,12,4,4,4,11,4,4,4,4,
	4,4,4,3,4,4,4,4,4,4,4,4,4,4,4,3,
	11,10,10,10,10,10,10,4,10,10,10,4,11,10,10,10,
	10,10,10,4,11,10,10,3,4,10,3,10,3,10,3,4,
	4,10,10,10,10,10,10,4,4,4,3,3,3,3,4,4,
	4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	12,12,12,8,8,12,12,12,12,12,8,14,8,12,12,12,
	12,12,8,8,14,8,12,12,12,12,8,8,12,12,12,12,
	12,12,12,14,11,12,12,12,12,12,12,14,11,12,12,12,
	12,12,12,14,11,12,12,12,12,12,12,14,11,12,12,12,
	4,10,4,8,4,4,10,4,4,10,8,13,8,4,10,4,
	4,10,8,8,4,8,10,4,4,8,13,4,8,4,10,4,
	4,4,4,11,4,4,4,4,4,4,4,11,4,4,4,4,
	4,4,4,11,4,4,4,4,4,4,4,11,4,4,4,4,
	0,0,0,0,0,0,0,0,7,6,0,7,6,6,6,7,
	5,6,7,6,7,6,7,5,5,7,6,6,6,6,7,6,
	6,7,6,7,6,6,6,6,5,7,6,7,6,7,6,5,
	7,6,6,6,7,0,6,7,6,0,7,7,6,6,0,7,
	6,0,7,7,0,6,0,7,6,11,3,4,11,10,10,11,
	10,11,10,11,4,10,10,11,11,4,3,4,11,10,5,6,
	10,11,10,11,4,10,10,11,11,4,3,4,11,10,10,11,
	6,0,7,7,6,0,7,6,7,6,7,6,5,7,6,5,
	7,6,5,7,7,6,5,7,0,0,0,0,7,0,13,6,
	6,6,5,5,6,7,5,5,6,7,6,6,6,6,7,0,
	0,0,0,0,0,7,6,6,6,11,6,6,5,5,7,6,
	5,5,5,5,6,5,5,5,5,6,6,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,5,4,5,5,
	4,10,5,0,0,5,5,0,6,7,0,6,6,7,6,7,
	0,11,10,11,10,10,10,11,11,4,3,4,11,10,10,11,
	11,10,10,4,11,10,10,11,10,11,10,11,4,10,10,11,
	0,0,0,0,11,10,10,11,11,11,0,0,11,11,0,0,
	0,0,0,10,4,3,10,3,3,3,3,10,4,4,11,0,
	0,0,11,10,4,3,10,3,3,3,3,10,4,4,11,0,
	0,0,0,11,11,0,11,10,4,10,10,11,11,0,0,0,
	3,3,3,4,4,3,4,3,3,3,3,10,4,3,10,3,
	10,11,11,11,4,10,10,11,11,4,3,4,11,10,10,11,
	10,11,10,11,4,10,10,11,11,4,3,4,11,10,10,11,
	10,11,10,11,4,10,10,11,11,4,3,10,11,11,10,3,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,2,2,1,1,1,2,2,2,2,2,2,1,
	3,10,11,11,10,4,4,3,3,3,3,3,11,3,3,4,
	10,11,10,11,4,3,4,4,3,3,10,11,4,4,3,3,
	3,3,11,10,10,4,3,3,15,13,13,13,13,11,15,13,
	13,11,15,13,13,11,15,13,13,11,15,13,13,13,13,11,
	15,13,13,11,15,13,13,13,13,13,12,11,15,13,13,11,
	13,13,13,11,15,13,13,13,15,13,15,14,13,11,11,11,
	15,13,15,14,13,11,11,11,15,13,13,13,13,13,12,11,
	13,12,12,10,12,12,12,12,12,12,12,11,12,12,11,10,
	12,12,12,11,12,12,12,12,12,10,0,0,0,0,13,12,
	12,12,12,10,12,12,12,12,11,3,11,10,11,10,4,10,
	14,11,14,11,13,11,13,11,13,11,13,11,13,11,13,11,
	14,13,14,13,14,13,14,11,11,3,11,10,11,10,4,10,
	11,4,3,10,10,11,10,11,11,4,3,10,11,10,10,11,
	12,12,12,11,11,12,12,12,4,4,4,3,4,4,4,4,
	4,4,4,3,4,4,4,4,4,4,4,4,4,4,3,3,
	10,10,10,10,10,10,10,4,10,10,10,4,10,10,10,10,
	10,10,10,4,10,10,10,4,4,10,3,10,3,10,3,4,
	4,3,3,3,3,3,3,4,4,4,3,3,3,3,4,4,
	4,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	12,12,8,14,8,12,12,12,12,8,8,13,13,8,12,12,
	12,12,8,13,8,12,12,12,12,8,8,8,8,8,12,12,
	12,12,12,11,11,12,12,12,12,12,12,11,11,12,12,12,
	12,12,12,11,11,12,12,12,12,12,12,11,11,12,12,12,
	10,4,8,14,8,4,4,4,10,8,8,8,4,8,4,4,
	10,8,13,8,13,4,4,4,4,8,8,8,4,4,4,4,
	4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,4,
	4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,4,
	0,0,0,0,0,0,0,0,0,6,5,7,5,6,7,7,
	6,7,6,6,6,5,7,6,6,6,5,6,7,6,7,6,
	5,6,7,6,5,7,6,7,6,7,5,6,6,6,7,6,
	7,7,6,5,7,5,6,0,6,6,6,0,6,5,7,6,
	7,6,7,0,5,6,7,6,10,4,3,3,11,4,3,11,
	11,10,4,10,10,4,3,10,10,4,3,3,11,4,10,6,
	11,10,4,10,10,4,3,10,10,4,3,3,11,4,3,11,
	7,6,5,6,7,6,6,7,5,6,7,5,7,6,7,6,
	5,7,6,7,6,7,6,7,0,0,0,7,13,7,7,5,
	6,7,6,6,7,13,7,6,7,11,5,6,5,7,6,6,
	0,0,0,0,0,13,7,0,7,6,5,5,5,6,11,5,
	5,11,6,6,5,5,4,5,6,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,10,4,4,
	10,0,0,0,0,0,0,0,7,6,6,5,6,7,5,5,
	11,10,4,10,10,4,3,10,10,4,3,3,11,4,10,11,
	11,10,4,3,11,4,3,11,11,10,4,10,10,4,10,11,
	0,0,0,0,0,11,0,11,11,0,0,0,0,0,0,0,
	0,11,10,4,3,3,4,10,3,3,4,4,3,3,10,11,
	0,11,10,4,3,3,4,10,3,3,4,4,3,3,10,11,
	0,0,0,0,0,0,0,11,11,11,0,0,0,0,0,0,
	3,3,4,4,3,3,4,4,3,3,4,4,3,3,4,10,
	11,10,4,10,10,4,3,10,10,4,3,3,11,4,3,11,
	11,10,4,10,10,4,3,10,10,4,3,3,11,4,3,11,
	11,10,4,10,10,4,3,10,10,4,3,3,11,10,11,11,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	2,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,
	3,10,11,10,10,4,3,3,3,3,3,3,11,3,4,4,
	11,11,11,10,3,3,3,4,3,3,10,11,10,4,3,4,
	3,3,11,11,10,4,3,3,13,11,11,11,11,11,13,11,
	11,11,13,11,11,11,13,11,11,11,13,11,11,11,11,11,
	13,11,11,11,13,11,11,11,11,11,11,11,13,11,11,11,
	11,11,11,11,13,11,11,11,15,14,15,14,13,11,12,10,
	15,14,15,14,12,11,12,10,13,11,11,11,11,11,11,11,
	11,11,10,4,10,11,11,11,11,11,11,10,11,11,11,4,
	11,11,11,4,10,11,11,10,11,11,0,0,0,0,12,10,
	11,11,10,4,10,11,11,11,10,4,10,3,11,4,3,4,
	14,13,14,13,14,13,14,11,14,13,14,13,14,13,14,11,
	11,11,11,11,11,11,11,11,10,4,10,3,11,4,3,4,
	10,4,3,3,11,4,3,11,10,4,3,3,11,4,3,11,
	11,11,11,4,10,11,11,10,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	4,3,4,3,4,4,3,3,4,4,4,3,4,4,3,3,
	4,4,4,3,4,4,3,3,3,10,3,10,3,10,3,3,
	3,4,4,4,4,4,4,3,3,4,4,4,4,4,4,3,
	3,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	11,8,8,13,14,8,11,10,11,12,8,14,8,11,11,10,
	11,8,13,8,8,8,11,10,11,12,8,14,8,11,11,10,
	11,11,11,4,10,11,11,10,11,11,11,4,10,11,11,10,
	11,11,11,4,10,11,11,10,11,11,11,4,10,11,11,10,
	3,8,8,8,8,8,3,3,3,4,14,8,14,4,3,3,
	3,8,14,8,8,4,3,3,3,4,8,14,8,4,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
	};