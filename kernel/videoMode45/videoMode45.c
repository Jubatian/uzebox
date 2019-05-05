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

#include <avr/io.h>
#include <avr/pgmspace.h>
#include "uzebox.h"
#if (M40_C64_GRAPHICS != 0)
#include "../videoMode40/data/c64_graphics.inc"
#endif
#if (M40_C64_ALPHA != 0)
#include "../videoMode40/data/c64_alpha.inc"
#endif
#if (M40_C64_MIXED != 0)
#include "../videoMode40/data/c64_mixed.inc"
#endif
#if (M40_IBM_ASCII != 0)
#include "../videoMode40/data/ibm_ascii.inc"
#endif
#if (M40_MATTEL != 0)
#include "../videoMode40/data/mattel.inc"
#endif


/* Callback invoked by UzeboxCore.Initialize() */
void InitializeVideoMode(){

	m45_config   = 0U;   /* Display Disabled, needs config first */
	m45_border   = 0U;
	m45_lastromt = 255U; /* No RAM tiles by default */
	SetFontTilesIndex(0x20U);

}

/* Callback invoked during vsync */
void VideoModeVsync(){
}

/* Callback invoked by UzeboxCore.Initialize() */
void DisplayLogo(){
}
