/*
 *  Uzebox video mode 72 simple demo
 *  Copyright (C) 2017 Sandor Zsuga (Jubatian)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <uzebox.h>



/* Sprite images (2bpp) */
static const unsigned char sprdata[] __attribute__ ((section (".text.align512"))) = {

 0b00000011U, 0b11111111U,
 0b00001111U, 0b01010111U,
 0b00111101U, 0b01010111U,
 0b11110101U, 0b01010111U,
 0b11110101U, 0b01010111U,
 0b00111101U, 0b01010111U,
 0b00001111U, 0b01010111U,
 0b00000011U, 0b11111111U,

 0b00000011U, 0b11111111U,
 0b00001111U, 0b01010111U,
 0b00111101U, 0b10100111U,
 0b11110110U, 0b10100111U,
 0b11110110U, 0b10100111U,
 0b00111101U, 0b10100111U,
 0b00001111U, 0b01010111U,
 0b00000011U, 0b11111111U,

 0b11111111U, 0b11111111U,
 0b11001111U, 0b01010111U,
 0b11111101U, 0b10100111U,
 0b11110110U, 0b10100111U,
 0b11110110U, 0b10100111U,
 0b11111101U, 0b10100111U,
 0b11001111U, 0b01010111U,
 0b11111111U, 0b11111111U,

 0b00000011U, 0b11001111U,
 0b00001111U, 0b00111111U,
 0b00111100U, 0b11110111U,
 0b11110011U, 0b11010111U,
 0b11110011U, 0b11010111U,
 0b00111100U, 0b11110111U,
 0b00001111U, 0b00111111U,
 0b00000011U, 0b11001111U,

};



/* Background */
static const unsigned char bgdata[] PROGMEM = {
 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x11U, 0x12U, 0x13U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x14U, 0x15U, 0x16U, 0x17U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x18U, 0x19U, 0x1AU, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x00U, 0x00U, 0x1BU, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,
 0x01U, 0x02U, 0x03U, 0x05U, 0x06U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U,

 0x09U, 0x0AU, 0x0AU, 0x0AU, 0x0BU, 0x05U, 0x06U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x11U, 0x12U, 0x13U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x08U, 0x01U, 0x02U,
 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0BU, 0x04U, 0x05U, 0x06U, 0x08U, 0x07U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x14U, 0x15U, 0x16U, 0x17U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x01U, 0x02U, 0x04U, 0x03U, 0x09U,
 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0AU, 0x0BU, 0x03U, 0x04U, 0x04U, 0x05U, 0x06U, 0x07U, 0x08U, 0x07U, 0x07U, 0x0EU, 0x0FU, 0x10U, 0x07U, 0x08U, 0x07U, 0x07U, 0x08U, 0x01U, 0x02U, 0x03U, 0x04U, 0x09U, 0x0AU, 0x0DU,
 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0AU, 0x0BU, 0x03U, 0x03U, 0x04U, 0x04U, 0x03U, 0x09U, 0x0AU, 0x0BU, 0x03U, 0x04U, 0x04U, 0x03U, 0x03U, 0x04U, 0x04U, 0x04U, 0x03U, 0x09U, 0x0AU, 0x0CU, 0x0CU, 0x0CU,
 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0AU, 0x0AU, 0x0AU, 0x0AU, 0x0AU, 0x0DU, 0x0CU, 0x0CU, 0x0BU, 0x03U, 0x03U, 0x09U, 0x0AU, 0x0AU, 0x0AU, 0x0AU, 0x0AU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,

 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,

 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0DU, 0x0CU, 0x0DU, 0x0CU, 0x0CU, 0x0CU,
};



/* " C-64 FONT " in PETSCII */
static const unsigned char txt_data[] PROGMEM = {
 0x20U, 0x03U, 0x2DU, 0x36U, 0x34U, 0x20U, 0x06U, 0x0FU, 0x0EU, 0x14U, 0x20U
};



void reset(void){
	M72_Halt();
}



static sprite_t main_sprites[48];
static bullet_t main_bullets[129];

static u8 main_vram[1024];
static u8 main_tram[256];


int main(void){

	u8  i;
	u8  j;
	u8  ct;
	u8  yp;
	u8  xp;

	/* Fill background */

	i = 0U;
	do{
		main_vram[i +   0U] = pgm_read_byte(&(bgdata[i +   0U]));
		main_vram[i + 256U] = pgm_read_byte(&(bgdata[i + 256U]));
		main_vram[i + 512U] = pgm_read_byte(&(bgdata[i + 512U]));
		main_vram[i + 768U] = pgm_read_byte(&(bgdata[i + 768U]));
		i ++;
	}while (i != 0U);

	/* Set up sprite chains */

	for (i = 0U; i < 8U; i++){
		main_sprites[i      ].next = &main_sprites[i +  8U];
		main_sprites[i +  8U].next = &main_sprites[i + 16U];
		main_sprites[i + 16U].next = &main_sprites[i + 24U];
		main_sprites[i + 24U].next = &main_sprites[i + 32U];
		main_sprites[i + 32U].next = &main_sprites[i + 40U];
		main_sprites[i + 40U].next = NULL;
		sprites[i] = &main_sprites[i];
	}

	/* VRAM start offsets */

	for (i = 0U; i < 32U; i++){
		m72_rowoff[i] = (u16)(&main_vram[(u16)(i) * 32U]);
	}

	/* Text mode VRAM contents */

	i = 0U;
	do{
		main_tram[i] = i;
		i ++;
	}while (i != 0U);
	for (i = 0U; i < sizeof(txt_data); i++){
		main_tram[i] = pgm_read_byte(&(txt_data[i]));
	}

	/* Configure mode */

	m72_tt_hgt = 0U;
	m72_tb_hgt = 0U;
	m72_tt_trows = 2U;
	m72_tb_trows = 2U;
	m72_tt_vram = &main_tram[ 0U];
	m72_tb_vram = &main_tram[40U];
	bordercolor = 0x52U;

	/* m72_reset = (unsigned int)(&reset); */

	m72_config = 0x04U; /* Sprite mode 0 */

	/* Set up sprites */

	for (i = 0U; i < 48U; i++){

		yp = (40U + ((i >> 1) *  7U));
		xp = (20U + ((i & 7U) * 15U) + ((i >> 3) * 5U));

		main_sprites[i].xpos   = xp;
		main_sprites[i].ypos   = 0U - yp;
		main_sprites[i].off    = ((u16)(&(sprdata[0])) & 0x7FFFU) + ((i & 1U) * 16U);
		main_sprites[i].off   |= (i & 1U) << 15; /* Mirror */
		main_sprites[i].height = 24U;
		main_sprites[i].col1   = 0x13U;
		main_sprites[i].col2   = 0x47U;
		main_sprites[i].col3   = 0x7FU;

	}

	/* Set up bullets */

	for (i = 0U; i < 128U; i++){
		if ((i & 0x10U) == 0U){
			main_bullets[i].xpos = 144U + (i & 0xFU);
		}else{
			main_bullets[i].xpos = 160U - (i & 0xFU);
		}
		main_bullets[i].ypos = 0U - (64U + i);
		main_bullets[i].height = (0U << 2) + 0U; /* Height, Width */
		main_bullets[i].col = 0xFFU;
	}
	main_bullets[128].ypos = 0U;
	main_bullets[128].height = 0U;
	bullets[0] = &main_bullets[0];

	/* Main loop */

	ct = 0U;

	while(1){

		/* Bg. scrolling */

		if ((ct & 0x80U) == 0U){
			j = (ct >> 1);
			for (i = 0U; i < 32U; i++){
				m72_rowoff[i] = (u16)(&main_vram[((u16)(i) * 32U) + (j >> 3)]) + ((u16)(j & 7U) << 12);
			}
		}else{
			j = 0x80U - (ct >> 1);
			for (i = 0U; i < 32U; i++){
				m72_rowoff[i] = (u16)(&main_vram[((u16)(i) * 32U) + (j >> 3)]) + ((u16)(j & 7U) << 12);
			}
		}

		/* Top / bottom text areas */

		if       (ct <  20U){
			m72_tt_hgt = ct;
			m72_tb_hgt = ct;
		}else if (ct < 120U){
			m72_tt_hgt = 20U;
			m72_tb_hgt = 20U;
		}else if (ct < 140U){
			m72_tt_hgt = 140U - ct;
			m72_tb_hgt = 140U - ct;
		}else{
			m72_tt_hgt = 0U;
			m72_tb_hgt = 0U;
		}

		/* Sprite movements */

		for (i = 0U; i < 48U; i++){

			yp = (40U + ((i >> 1) *  7U));
			xp = (20U + ((i & 7U) * 15U) + ((i >> 3) * 5U));
			if (((ct + i) & 0x80U) != 0U){ yp ++; }
			if (((ct + i) & 0x40U) != 0U){ xp ++; }
			if (((ct + i + 32U) & 0x40U) != 0U){ yp ++; }
			if (((ct + i + 16U) & 0x20U) != 0U){ xp ++; }
			if (((ct + i + 16U) & 0x20U) != 0U){ yp ++; }
			if (((ct + i +  8U) & 0x10U) != 0U){ xp ++; }
			if (((ct + i +  8U) & 0x10U) != 0U){ yp ++; }
			if (((ct + i +  4U) & 0x08U) != 0U){ xp ++; }

			main_sprites[i].xpos = xp;
			main_sprites[i].ypos = 0U - yp;

		}

		/* Bullet width animation */

		for (i = 0U; i < 128U; i++){
			main_bullets[i].height = ((ct + i) >> 5) & 3U;
		}

		ct ++;


		WaitVsync(1);

	}

}
