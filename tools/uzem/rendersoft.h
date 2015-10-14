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


#ifndef RENDERSOFT_H
#define RENDERSOFT_H

#include "renderif.h"
#include "SDL2/SDL.h"


// Maximal length of status string
#define RENDERSOFT_STATUS_LEN 1024U


class renderSoft: public renderIf
{
public:
	renderSoft();
	~renderSoft();

	// See renderif
	bool init();

	// See renderIf
	void line(uint8 const* lbuf, auint llen, auint lno,
	          auint hsync, auint vsync);

	// See renderif
	bool setProp(auint prop, asint val);

	// See renderif
	bool setProp(auint prop, asint val, bool delay);

	// See renderif
	asint getProp(auint prop);

	// See renderIf
	void tick();

	// See renderIf
	void setStatusStr(char const* str);

	// See renderif
	void getLine(uint32* dest, auint lno);

	// See renderIf
	void* getFrame(void);

	// See renderIf
	void getPixelFormatString(char* pix_fmt);

private:
	void destroy();

	bool         o_isinit;
	SDL_Window*  o_window;
	SDL_Surface* o_wsurf;
	auint        o_palette[256];
	auint        o_hoff;
	auint        o_voff;
	bool         o_full;
	auint        o_prevl;
	char         o_status[RENDERSOFT_STATUS_LEN];
	bool         o_isfill[525];
};


#endif
