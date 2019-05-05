/*
 *  Uzebox Kernel - Mode 45
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
 *
 *  Uzebox is a reserved trade mark
*/

/**
 * ===========================================================================
 * Function prototypes for video mode 45
 * ===========================================================================
 */

#pragma once

#include <avr/io.h>

/* Provided by VideoMode45.s */

extern unsigned char const* m45_rowdesc;
extern unsigned char*       m45_col0;
extern unsigned char*       m45_linesel;
extern unsigned char        m45_lastromt;
extern unsigned char        m45_config;
extern unsigned char        m45_border;

/* Supplementary functions to complement the Uzebox kernel's set */

void          ClearAram(void);
void          SetAttr(char x, char y, unsigned char attr);
unsigned int  GetTile(char x, char y);
unsigned char GetAttr(char x, char y);
unsigned char GetFont(char x, char y);

/* Global configuration flags */

#define M45_CONFIG_COLREP0  0x01U
#define M45_CONFIG_BORDER0  0x02U
#define M45_CONFIG_RAMDESC  0x04U
#define M45_CONFIG_DISPENA  0x80U

/* Optional charsets */

#if (M40_C64_GRAPHICS != 0)
extern const char m40_c64_graphics[] PROGMEM;
#endif
#if (M40_C64_ALPHA != 0)
extern const char m40_c64_alpha[] PROGMEM;
#endif
#if (M40_C64_MIXED != 0)
extern const char m40_c64_mixed[] PROGMEM;
#endif
#if (M40_IBM_ASCII != 0)
extern const char m40_ibm_ascii[] PROGMEM;
#endif
#if (M40_MATTEL != 0)
extern const char m40_mattel[] PROGMEM;
#endif
