/*
Screenshot function

-----

(The MIT License)

Copyright (c) 2008-2015 by
David Etherton, Eric Anderton, Alec Bourque (Uze), Filipe Rinaldi,
Sandor Zsuga (Jubatian), Matt Pandina (Artcfox)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/


#include "screenshot.h"
#include "SDL2/SDL.h"



// Screenshot number
static auint screenshot_no = 0U;



void screenShot(renderIf* ren)
{
	char         ssbuf[64];
	SDL_Surface* surf;
	auint        wdt = RENDERIF_N_WIDTH;
	auint        hgt = RENDERIF_N_HEIGHT;

	if (ren->getProp(RENDERIF_PROP_DEBUG) != 0)
	{
		wdt = RENDERIF_D_WIDTH;
		hgt = RENDERIF_D_HEIGHT;
	}

	surf = SDL_CreateRGBSurface(0U, wdt, hgt, 32U, 0x00FF0000U, 0x0000FF00U, 0x000000FFU, 0U);
	if (surf == NULL)
	{
		printf("Unable to create screenshot: %s\n", SDL_GetError());
		return;
	}

	for (auint i = 0U; i < hgt; i++)
	{
		ren->getLine((uint32*)(&((uint8*)(surf->pixels))[i * surf->pitch]) , i);
	}

	sprintf(ssbuf, "uzem_%03u.bmp", (unsigned int)(screenshot_no++));
	printf("Saving screenshot to '%s'...\n", ssbuf);

	if (SDL_SaveBMP(surf, ssbuf) != 0)
	{
		printf("Unable to create screenshot: %s\n", SDL_GetError());
	}

	SDL_FreeSurface(surf);
}

void writeFrame(renderIf* ren, FILE *fp)
{
	fwrite(ren->getFrame(), RENDERIF_N_WIDTH*RENDERIF_N_HEIGHT*4, 1, fp);
}
