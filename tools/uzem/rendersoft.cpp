/*
Software renderer

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


#include "rendersoft.h"
#include "rendersupp.h"
#include <stdlib.h>



// Width of the display surface
#define DISPLAY_WIDTH   RENDERIF_N_WIDTH
// Height of the display surface
#define DISPLAY_HEIGHT  RENDERIF_N_HEIGHT



renderSoft::renderSoft()
{
	o_status[0] = 0;
	o_hoff = RENDERIF_HOFF - (((DISPLAY_WIDTH / 3) * 7) / 2);
	o_voff = RENDERIF_VOFF - (DISPLAY_HEIGHT / 2);
	o_full = false;
	o_isinit = false;
}



renderSoft::~renderSoft()
{
	destroy();
	// This is only for debugging. For some reason fullscreen now
	// doesn't work (jumbled up screen, although program runs), and
	// neither restores original resolution after return, even though
	// the destructor is called.
	printf("Renderer destroyed\n");
}



void renderSoft::destroy()
{
	if (!o_isinit)
	{
		return;
	}
	SDL_DestroyWindow(o_window);
	o_isinit = false;
}



bool renderSoft::init()
{
	destroy();

	o_window = SDL_CreateWindow(o_status,
	                            SDL_WINDOWPOS_CENTERED,
	                            SDL_WINDOWPOS_CENTERED,
	                            DISPLAY_WIDTH,
	                            DISPLAY_HEIGHT,
	                            o_full?SDL_WINDOW_FULLSCREEN:0U);
	if (o_window == NULL)
	{
		fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
		return false;
	}

	o_wsurf = SDL_GetWindowSurface(o_window);
	if (o_wsurf == NULL)
	{
		SDL_DestroyWindow(o_window);
		fprintf(stderr, "SDL_GetWindowSurface failed: %s\n", SDL_GetError());
		return false;
	}

	if ((o_wsurf->format->BytesPerPixel) != 4U)
	{
		SDL_DestroyWindow(o_window);
		fprintf(stderr, "Display: Only 32 bit depth is supported (for now)\n");
		return false;
	}

	if (o_full)
	{
		SDL_ShowCursor(0);
	}

	for (auint i = 0U; i < 256U; i ++)
	{
		auint r = (((i >> 0) & 7U) * 0xFFU) / 7U;
		auint g = (((i >> 3) & 7U) * 0xFFU) / 7U;
		auint b = (((i >> 6) & 3U) * 0xFFU) / 3U;
		o_palette[i] = SDL_MapRGB(o_wsurf->format, r, g, b);
	}

	for (auint i = 0U; i < DISPLAY_HEIGHT; i ++)
	{
		o_isfill[i] = false;
	}

	o_prevl = 0U;

	o_isinit = true;
	return true;
}



void renderSoft::line(uint8 const* lbuf, auint llen, auint lno,
                      auint hsync, auint vsync)
{
	if (!o_isinit)
	{
		return;
	}

	// For now only support progressive scan

	if (o_prevl > lno) // New frame started
	{

		for (auint i = 0U; i < DISPLAY_HEIGHT; i ++)
		{
			if (!o_isfill[i])
			{
				memset((uint8*)(o_wsurf->pixels) + (i * o_wsurf->pitch), 0U, DISPLAY_WIDTH * 4U);
			}
			o_isfill[i] = false;
		}
		SDL_UpdateWindowSurface(o_window);

		// If fullscreen, then keep the mouse centered so relative
		// mouse motion events may keep coming independent of the
		// actual mouse position. Also consume the relative motion
		// caused by this action. This is not an ideal solution, but
		// works for now ("bogus" mouse motion events are still
		// generated, only works if the input code uses
		// GetRelativeMouseState to follow the mouse).

		if (o_full)
		{
			SDL_WarpMouseInWindow(o_window, DISPLAY_WIDTH >> 1, DISPLAY_HEIGHT >> 1);
			int dummyx, dummyy;
			SDL_GetRelativeMouseState(&dummyx, &dummyy);
		}

	}

	// Note: For small line numbers, due to unsigned arithmetic, it wraps,
	// so the '<' check will fail proper.

	if ((lno - o_voff) < DISPLAY_HEIGHT)
	{
		auint voff = (lno - o_voff);
		rendersupp_line32(
			(uint32*)(&((uint8*)(o_wsurf->pixels))[((voff     ) * o_wsurf->pitch)]),
			(uint32*)(&((uint8*)(o_wsurf->pixels))[((voff ^ 1U) * o_wsurf->pitch)]),
			lbuf, o_hoff, DISPLAY_WIDTH,
			o_palette);
		o_isfill[voff     ] = true;
		o_isfill[voff ^ 1U] = true;
	}

	o_prevl = lno;
}



bool renderSoft::setProp(auint prop, asint val)
{
	return setProp(prop, val, false);
}


bool renderSoft::setProp(auint prop, asint val, bool delay)
{
	bool need_init = false;

	switch (prop)
	{
	case RENDERIF_PROP_HOFF:
		val += RENDERIF_HOFF - (((DISPLAY_WIDTH / 3) * 7) / 2);
		if      (val < 0)
		{
			o_hoff = 0U;
		}
		else if (val > 2048 - ((DISPLAY_WIDTH / 3) * 7))
		{
			o_hoff = 2048 - ((DISPLAY_WIDTH / 3) * 7);
		}
		else
		{
			o_hoff = (auint)(val);
		}
		break;

	case RENDERIF_PROP_VOFF:
		val += RENDERIF_VOFF - (DISPLAY_HEIGHT / 2);
		if      (val < 0)
		{
			o_voff = 0U;
		}
		else if (val > 525 - DISPLAY_HEIGHT)
		{
			o_voff = 525 - DISPLAY_HEIGHT;
		}
		else
		{
			o_voff = (auint)(val);
		}
		break;

	case RENDERIF_PROP_FULL:
		if (o_full && (val == 0))
		{
			o_full = false;
			need_init = true;
		}
		if (!o_full && (val != 0))
		{
			o_full = true;
			need_init = true;
		}
		break;

	default:
		break;
	}

	if (need_init && !delay && o_isinit)
	{
		return init();
	}
	else
	{
		return true;
	}
}



asint renderSoft::getProp(auint prop)
{
	switch (prop)
	{
	case RENDERIF_PROP_HOFF:
		return o_hoff;
	case RENDERIF_PROP_VOFF:
		return o_voff;
	case RENDERIF_PROP_FULL:
		if (o_full)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	case RENDERIF_PROP_WIDTH:
		return DISPLAY_WIDTH;
	case RENDERIF_PROP_HEIGHT:
		return DISPLAY_HEIGHT;
	case RENDERIF_PROP_DEBUG:
		return 0;
	default:
		return 0;
	}
}



void renderSoft::tick()
{
	if (!o_isinit)
	{
		return;
	}
}



void renderSoft::setStatusStr(char const* str)
{
	auint i;

	for (i = 0U; i < (RENDERSOFT_STATUS_LEN - 1U); i++)
	{
		if (str[i] == 0)
		{
			break;
		}
		o_status[i] = str[i];
	}
	o_status[i] = 0;

	if (o_isinit)
	{
		SDL_SetWindowTitle(o_window, str);
	}
}



void renderSoft::getLine(uint32* dest, auint lno)
{
	if (lno < DISPLAY_HEIGHT)
	{
		rendersupp_convsurf(dest, o_wsurf, lno, 0U, DISPLAY_WIDTH);
	}
}

void* renderSoft::getFrame(void)
{
	return o_wsurf->pixels;
}

void renderSoft::getPixelFormatString(char* pix_fmt)
{
	// Detect the pixel format that the GPU picked for optimal speed
	strcpy(pix_fmt, "aaaa\0");

	switch (o_wsurf->format->Rmask) {
	case 0xff000000: pix_fmt[3] = 'r'; break;
	case 0x00ff0000: pix_fmt[2] = 'r'; break;
	case 0x0000ff00: pix_fmt[1] = 'r'; break;
	case 0x000000ff: pix_fmt[0] = 'r'; break;
	}
	switch (o_wsurf->format->Gmask) {
	case 0xff000000: pix_fmt[3] = 'g'; break;
	case 0x00ff0000: pix_fmt[2] = 'g'; break;
	case 0x0000ff00: pix_fmt[1] = 'g'; break;
	case 0x000000ff: pix_fmt[0] = 'g'; break;
	}
	switch (o_wsurf->format->Bmask) {
	case 0xff000000: pix_fmt[3] = 'b'; break;
	case 0x00ff0000: pix_fmt[2] = 'b'; break;
	case 0x0000ff00: pix_fmt[1] = 'b'; break;
	case 0x000000ff: pix_fmt[0] = 'b'; break;
	}
}
