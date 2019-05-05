/*
 *  Uzebox video mode 45 simple demo
 *  Copyright (C) 2019 Sandor Zsuga (Jubatian)
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
#include "memory.h"


/*
** Line selectors
*/
static unsigned char lsel[8] =
{
   0U,
 192U, 0U,
 255U
};


int main(){

	unsigned int i;
	unsigned int j;

	m45_rowdesc  = &memory_rowdesc[0];
	m45_linesel  = &lsel[0];
	m45_border   = 07U;
	m45_lastromt = 191U;
	m45_config   = M45_CONFIG_DISPENA;

	ClearVram();
	ClearAram();

	for (j = 0U; j < 32U; j ++)
	{
		for (i = 0U; i < VRAM_TILES_H; i ++)
		{
			SetTile(i, j, (i ^ 0xFFU) & ((j << 3) | 0x7U));
			SetAttr(i, j, (i        ) | ((j << 3)       ));
		}
	}

	j = 0U;
	i = 0U;

	while(1)
	{
		WaitVsync(1);
		lsel[0] --;
		lsel[2] ++;

		j += 3U;
		i += 5U;

		memory_ramtiles[(256U * 0U) + 192U + (i & 0x3FU)] = (j     ) & 0xFFU;
		memory_ramtiles[(256U * 1U) + 192U + (i & 0x3FU)] = (j >> 1) & 0xFFU;
		memory_ramtiles[(256U * 2U) + 192U + (i & 0x3FU)] = (j >> 2) & 0xFFU;
		memory_ramtiles[(256U * 3U) + 192U + (i & 0x3FU)] = (j >> 3) & 0xFFU;
		memory_ramtiles[(256U * 4U) + 192U + (i & 0x3FU)] = (j >> 4) & 0xFFU;
		memory_ramtiles[(256U * 5U) + 192U + (i & 0x3FU)] = (j >> 5) & 0xFFU;
		memory_ramtiles[(256U * 6U) + 192U + (i & 0x3FU)] = (j >> 6) & 0xFFU;
		memory_ramtiles[(256U * 7U) + 192U + (i & 0x3FU)] = (j >> 7) & 0xFFU;
	}

}
