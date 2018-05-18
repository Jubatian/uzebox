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



#define CFG0_COLRELOAD (M52_CFG0_NOATTR | M52_CFG0_COL0_RELOAD | M52_CFG0_COL1_RELOAD)

static const m52_rowdesc_t rows[32] PROGMEM = {
 { (u8*)(0x0400U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_10 },
 { (u8*)(0x0420U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_12 },
 { (u8*)(0x0440U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_14 },
 { (u8*)(0x0460U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_16 },
 { (u8*)(0x0480U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_18 },
 { (u8*)(0x04A0U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_20 },
 { (u8*)(0x04C0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_22 },
 { (u8*)(0x04E0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_24 },

 { (u8*)(0x0500U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_26 },
 { (u8*)(0x0520U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_28 },
 { (u8*)(0x0540U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_30 },
 { (u8*)(0x0560U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 },
 { (u8*)(0x0580U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_34 },
 { (u8*)(0x05A0U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_36 },
 { (u8*)(0x05C0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_36 },
 { (u8*)(0x05E0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_34 },

 { (u8*)(0x0600U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 },
 { (u8*)(0x0620U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_30 },
 { (u8*)(0x0640U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_28 },
 { (u8*)(0x0660U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_26 },
 { (u8*)(0x0680U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_24 },
 { (u8*)(0x06A0U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_22 },
 { (u8*)(0x06C0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_20 },
 { (u8*)(0x06E0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_18 },

 { (u8*)(0x0700U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_16 },
 { (u8*)(0x0720U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_14 },
 { (u8*)(0x0740U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_12 },
 { (u8*)(0x0760U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_10 },
 { (u8*)(0x0780U), CFG0_COLRELOAD,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 },
 { (u8*)(0x07A0U), M52_CFG0_ATTR0,   M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 },
 { (u8*)(0x07C0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 },
 { (u8*)(0x07E0U), M52_CFG0_ATTR23M, M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_32 }
};

static u8 rowsel[2] = { 0U, 255U };



static M52_ROMTILESET_PRE u8 test_tiles[1U * 16U] M52_ROMTILESET_POST = {
 0x1BU, 0xE4U,
 0x6FU, 0x90U,
 0xBEU, 0x41U,
 0xF9U, 0x06U,
 0xBEU, 0x41U,
 0x6FU, 0x90U,
 0x1BU, 0xE4U,
 0x06U, 0xF9U,
};



int main(){

	m52_palette[0] = 0x07;
	m52_palette[1] = 0x07 << 3;
	m52_palette[2] = 0x03 << 6;
	m52_palette[3] = 0xFF;

	uint16_t i = 0U;

	m52_rowsel_p = &rowsel[0];
	m52_ramt_base = 0xC0U;
	m52_col0_p = (u8*)(0x0400U);
	m52_col1_p = (u8*)(0x0500U);
	M52_SetTileset(0U, test_tiles, NULL);
	M52_LoadRowDesc(rows);

	m52_config = M52_CFG_ENABLE;

	for (i = 0x0800U; i < 0x0C00U; i++){
		u8 c0 = (i >> 2)  & 3U;
		u8 c1 = (c0 + 1U) & 3U;
		u8 c2 = (c1 + 1U) & 3U;
		u8 c3 = (c2 + 1U) & 3U;
		*((u8*)(i)) = c0 + (c1 << 2) + (c2 << 4) + (c3 << 6);
	}

	for (i = 0x0C00U; i < 0x1000U; i++){
		u8 c = (i >> 4) & 3U;
		*((u8*)(i)) = c + (c << 2) + (c << 4) + (c << 6);
	}

	while(1){
		WaitVsync(1);
		i ++;
		((unsigned char*)(0x0039U))[0] = i & 0xFFU;
		((unsigned char*)(0x0039U))[1] = i >> 8;

		m52_rowdesc[(i >> 5) & 0x1FU].vram[i & 0x1FU] = i & 0xFFU;

		for (u8 j = 0U; j < 32U; j++){
			m52_rowdesc[j].cfg0 &= 0xF8U;
			m52_rowdesc[j].cfg0 |= (i >> 1) & 7U;
			m52_rowdesc[j].vram  = (u8*)(0x0400U) + ((u16)(j) * 32U) + ((i >> 4) & 0x7FU);
		}

	}

}
