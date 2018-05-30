/*
 *  Uzebox mode 8 testing
 *  Copyright (C) 2016 Alec Bourque,
 *                     Sandor Zsuga (Jubatian)
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

#include "tilestop.h"
#include "tilesbot.h"
#include "fontdata.h"
#include "planemap.h"


#define CFG0_PLANE (M52_CFG0_NOATTR | M52_CFG0_COL0_RELOAD)
#define CFG1_PLANE (M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_36)

#define CFG0_EXT   (M52_CFG0_NOATTR | M52_CFG0_SPR_OFF)
#define CFG1_EXT   (M52_CFG1_ROMT_2 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_36)


static u8 imgrows[30][40];
static u8 extrows[ 2][40];


static const m52_rowdesc_t rows[32] PROGMEM = {
 { imgrows[ 0], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 1], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 2], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 3], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 4], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 5], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 6], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 7], CFG0_PLANE, CFG1_PLANE },

 { imgrows[ 8], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 9], CFG0_PLANE, CFG1_PLANE },
 { imgrows[10], CFG0_PLANE, CFG1_PLANE },
 { imgrows[11], CFG0_PLANE, CFG1_PLANE },
 { imgrows[12], CFG0_PLANE, CFG1_PLANE },
 { imgrows[13], CFG0_PLANE, CFG1_PLANE },
 { imgrows[14], CFG0_PLANE, CFG1_PLANE },
 { imgrows[15], CFG0_PLANE, CFG1_PLANE },

 { imgrows[16], CFG0_PLANE, CFG1_PLANE },
 { imgrows[17], CFG0_PLANE, CFG1_PLANE },
 { imgrows[18], CFG0_PLANE, CFG1_PLANE },
 { imgrows[19], CFG0_PLANE, CFG1_PLANE },
 { imgrows[20], CFG0_PLANE, CFG1_PLANE },
 { imgrows[21], CFG0_PLANE, CFG1_PLANE },
 { imgrows[22], CFG0_PLANE, CFG1_PLANE },
 { imgrows[23], CFG0_PLANE, CFG1_PLANE },

 { imgrows[24], CFG0_PLANE, CFG1_PLANE },
 { imgrows[25], CFG0_PLANE, CFG1_PLANE },
 { imgrows[26], CFG0_PLANE, CFG1_PLANE },
 { imgrows[27], CFG0_PLANE, CFG1_PLANE },
 { imgrows[28], CFG0_PLANE, CFG1_PLANE },
 { imgrows[29], CFG0_PLANE, CFG1_PLANE },
 { extrows[ 0], CFG0_EXT,   CFG1_EXT   },
 { extrows[ 1], CFG0_EXT,   CFG1_EXT   },
};

static u8 rowsel[6] = { 0U, 255U, 0U, 0U, 0U, 0U };

static u8 sprite_ws[80U * 3U];

static u8 color0[224];


int main(){

	m52_palette[0] = 0x00U;
	m52_palette[1] = 0x52U;
	m52_palette[2] = 0xA4U;
	m52_palette[3] = 0xB6U;

	u16 i = 0U;

	m52_rowsel_p = &rowsel[0];
	m52_ramt_base = 0xC0U;
	m52_col0_p = &color0[0];
	M52_SetTileset(0U, tilestop, NULL);
	M52_SetTileset(1U, tilesbot, NULL);
	M52_SetTileset(2U, fontdata, NULL);
	M52_LoadRowDesc(rows);
	m52_sprite_work_p = &sprite_ws[0];
	m52_sprite_ramt_base = 0xC0U;
	m52_sprite_ramt_max = 64U;

	m52_config = M52_CFG_ENABLE | M52_CFG_COL0_PHY;

	for (u8 col = 0U; col < 224U; col ++){
		color0[col] = col & 0xDFU;
	}

	for (u8 y = 0U; y < 30U; y ++){
		for (u8 x = 0U; x < 40U; x ++){
			m52_rowdesc[y].vram[x] = 99U;
		}
	}

	for (u8 y = 0U; y < 9U; y ++){
		for (u8 x = 0U; x < 29U; x ++){
			m52_rowdesc[y + 10U].vram[x + 5U] = pgm_read_byte(&planemap[((uint16_t)(y) * 29U) + x]);
		}
		if (y > 4U){ m52_rowdesc[y + 10U].cfg1 |= M52_CFG1_ROMT_1; }
	}

	for (u8 j = 0U; j < 26U; j ++){
		m52_rowdesc[30U].vram[j] = 'a' + j;
		m52_rowdesc[31U].vram[j] = 'A' + j;
	}

	M52_ResReset();

	while(1){
		i ++;
		WaitVsync(2);

		M52_VramRestore();

		rowsel[1] = i & 0xFFU;
		rowsel[2] = 240U;
		rowsel[3] = (i + 16U) & 0xFFU;
		rowsel[4] = (i + 16U) & 0xFFU;
		rowsel[5] = 255U;

		for (u8 j = 0U; j < 28U; j ++){
			u8 sh = (i >> 2) & 0x3FU;
			if ((sh & 0x20U) != 0U){ sh = 0x3FU - sh; }
			m52_rowdesc[j].vram = &(imgrows[j][0]) + (sh >> 3);
			m52_rowdesc[j].cfg0 = CFG0_PLANE | (sh & 7U);
		}

		for (u8 j = 0U; j < 26U; j ++){
			M52_BlitSpriteRom(&fontdata[(uint16_t)('a' + j) * 16U],
			    (20U + (i >> 1) + (j * 13U)) & 0x1FFU,
			    ((i >> 1) & 0xFFU) + (j << 1),
			    M52_SPR_I3);
		}

//		for (uint8_t y = 0U; y < 8U; y++){
//			for (uint8_t x = 0U; x < 8U; x++){
//				M52_PutPixel((i >> 6) & 3U, 128U + x, 64U + y, M52_SPR_I1);
//			}
//		}

//		for (uint8_t j = 0U; j < 100U; j++){
//			M52_PutPixel((i >> 6) & 3U, 64U + j /*+ ((i >> 4) & 0xFU)*/, j, M52_SPR_I1);
//		}

//		M52_PutPixel((i >> 6) & 3U,  0U, 0U, M52_SPR_I1);
//		M52_PutPixel((i >> 6) & 3U,  8U, 0U, M52_SPR_I1);
//		M52_PutPixel((i >> 6) & 3U, 16U, 0U, M52_SPR_I1);
//		M52_PutPixel((i >> 6) & 3U, 24U, 0U, M52_SPR_I1);
//		M52_PutPixel((i >> 6) & 3U, 32U, 0U, M52_SPR_I1);

	}

}
