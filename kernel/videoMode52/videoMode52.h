/*
 *  Uzebox Kernel - Video Mode 52
 *  Copyright (C) 2018 Sandor Zsuga (Jubatian)
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
 *
 *  Uzebox is a reserved trade mark
*/

/**
 * ===========================================================================
 *
 * This file contains function prototypes and exports for mode 52
 * For documentations, see the comments in videoMode52.s
 *
 * ===========================================================================
 */

#pragma once

#include <uzebox.h>
#if (M52_USE_NAS == 0)
#include <avr/pgmspace.h>
#define M52_FLASHPTR const
#define M52_ROMTILESET_PRE const
#define M52_ROMTILESET_POST PROGMEM __attribute__((aligned(256)))
#else
#define M52_FLASHPTR const __flash
#define M52_ROMTILESET_PRE const __flash
#define M52_ROMTILESET_POST __attribute__((aligned(256)))
#endif



/*
** Row descriptor
*/
typedef struct{
 u8* vram;             /* VRAM address */
 u8  cfg0;             /* Config byte 0 (Color 0, Mode, Sprite blit disable, X shift */
 u8  cfg1;             /* Config byte 1 (ROM tileset, Palette, Display width) */
}m52_rowdesc_t;


/*
** See documentations in videoMode52.s
*/
extern volatile u8  m52_config;
extern u8* volatile m52_rowsel_p;
extern m52_rowdesc_t m52_rowdesc[32];
extern volatile u8  m52_palette[16];
extern volatile u8  m52_ramt_base;
extern u8* volatile m52_col0_p;
extern u8* volatile m52_col1_p;
#if (M52_RESET_ENABLE != 0)
extern volatile u16 m52_reset;
#endif
extern volatile u8  m52_rtmax;
extern volatile u8  m52_rtbase;

void M52_SetTileset(u8 tsno, M52_FLASHPTR u8* data, M52_FLASHPTR u8* mski);
void M52_LoadRowDesc(M52_FLASHPTR m52_rowdesc_t* data);
void M52_RamTileFillRom(M52_FLASHPTR u8* src, u8 dst);
void M52_RamTileFillRam(u8  src, u8 dst);
void M52_RamTileClear(u8 dst);
void M52_Halt(void) __attribute__((noreturn));
void M52_Seq(void);
#if (M52_SPR_ENABLE != 0)
void M52_VramRestore(void);
void M52_BlitSprite(u16 spo, u8 xl, u8 yl, u8 flg);
void M52_BlitSpriteCol(u16 spo, u8 xl, u8 yl, u8 flg, u8 col);
void M52_PutPixel(u8 col, u8 xl, u8 yl, u8 flg);
#endif


/*
** Macro to get RAM tile pointer (for rendering into RAM tiles with user code)
*/
#define M52_RAMTILE_P(tile) ((u8*)((u16)(tile) * 16U))


/*
** Sprite blitter flags, for use with M52_BlitSprite.
** Sprite importance is ignored in this mode, it is left only for
** compatibility with Mode 74.
*/
#define M52_SPR_FLIPX            0x01U
#define M52_SPR_FLIPY            0x04U
#define M52_SPR_SPIRAM_A16       0x02U
#define M52_SPR_MASK             0x10U
#define M52_SPR_I3               0xC0U
#define M52_SPR_I2               0x80U
#define M52_SPR_I1               0x40U
#define M52_SPR_I0               0x00U


/*
** Configuration (m52_config) flags.
*/
#define M52_CFG_ENABLE           0x01U
#define M52_CFG_COL0_PHY         0x04U

/*
** Row descriptor cfg0 flags (X shift is on bits 0-2).
*/
#define M52_CFG0_SPR_OFF         0x08U
#define M52_CFG0_ATTRMASK        0x30U
#define M52_CFG0_NOATTR          0x00U
#define M52_CFG0_ATTR0           0x10U
#define M52_CFG0_ATTR123         0x20U
#define M52_CFG0_ATTR23M         0x30U
#define M52_CFG0_COL0_RELOAD     0x40U
#define M52_CFG0_COL1_RELOAD     0x80U

/*
** Row descriptor cfg1 flags.
*/
#define M52_CFG1_ROMT_0          0x00U
#define M52_CFG1_ROMT_1          0x01U
#define M52_CFG1_ROMT_2          0x02U
#define M52_CFG1_ROMT_3          0x03U
#define M52_CFG1_PAL_0           0x00U
#define M52_CFG1_PAL_1           0x04U
#define M52_CFG1_PAL_2           0x08U
#define M52_CFG1_PAL_3           0x0CU
#define M52_CFG1_WIDTH_10        0x00U
#define M52_CFG1_WIDTH_12        0x10U
#define M52_CFG1_WIDTH_14        0x20U
#define M52_CFG1_WIDTH_16        0x30U
#define M52_CFG1_WIDTH_18        0x40U
#define M52_CFG1_WIDTH_20        0x50U
#define M52_CFG1_WIDTH_22        0x60U
#define M52_CFG1_WIDTH_24        0x70U
#define M52_CFG1_WIDTH_26        0x80U
#define M52_CFG1_WIDTH_28        0x90U
#define M52_CFG1_WIDTH_30        0xA0U
#define M52_CFG1_WIDTH_32        0xB0U
#define M52_CFG1_WIDTH_34        0xC0U
#define M52_CFG1_WIDTH_36        0xD0U
