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

#include "uzebox.h"



/* Callback invoked by UzeboxCore.Initialize() */
void DisplayLogo(){

}



/* Callback invoked by UzeboxCore.Initialize() */
void InitializeVideoMode()
{
	m52_config = 0U;    /* Display disabled */
#if (M52_RESET_ENABLE != 0)
	m52_reset  = 0U;    /* Reset starts off disabled (so logo may display) */
#endif
#if (M52_SPR_ENABLE != 0)
	m52_sprite_ramt_max = 0U; /* Initially disable sprites by giving 0 RAM tiles */
#endif
}



/* Callback invoked during hsync */
void VideoModeVsync(){
	ProcessFading();
}
