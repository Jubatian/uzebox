/*
Renderer interface

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


#ifndef RENDERIF_H
#define RENDERIF_H

#include "types.h"


// Default horizontal offset relative to the center of the display in cycles
#define RENDERIF_HOFF     886

// Defualt vertical offset relative to the center of the display in lines
// Note: This assumes 525 lines! (Halve for progressive scan)
#define RENDERIF_VOFF     300

// Unscaled height of visible area in rows in normal mode. Center of the
// display should be at the half of this.
#define RENDERIF_N_HEIGHT 448U

// Unscaled width of visible area in pixels in normal mode (1442 cycles,
// 2,333333 cycles / pixel). Center of the display should be at the half of
// this. If the renderer's aspect ratio differs, it should center its display
// over this area.
#define RENDERIF_N_WIDTH  618U

// Unscaled height of visible area in rows in debug mode
#define RENDERIF_D_HEIGHT 530U

// Unscaled width of visible area in pixels in debug mode (1848 cycles,
// 2,333333 cycles / pixel).
#define RENDERIF_D_WIDTH  792U


// Property: Horizontal offset
// This should shift the picture horizontally by cycles, negative to the left,
// positive to the right.
#define RENDERIF_PROP_HOFF     0U

// Property: Vertical offset
// This should shift the picture vertically by (interlaced) lines, negative to
// the top, positive to the bottom.
#define RENDERIF_PROP_VOFF     1U

// Property: Fullscreen
// If set (nonzero), the renderer should attempt to render full screen,
// otherwise windowed.
#define RENDERIF_PROP_FULL     2U

// Property: Display width
// The preferred width (pixels) of the output picture.
#define RENDERIF_PROP_WIDTH    3U

// Property: Display height
// The preferred height (pixels) of the output picture.
#define RENDERIF_PROP_HEIGHT   4U

// Property: Debug mode
// If set (nonzero), debug mode is enabled. In debug mode the renderer should
// attempt to display all cycles, with some kind of indications on where the
// horizontal and vertical blankings are (and whether they conform the
// requirements of proper NTSC output). Output is debug mode horizontally
// begins at the start of the received line buffer (the end of the HSync
// pulse), and vertically at line zero.
#define RENDERIF_PROP_DEBUG    5U



class renderIf
{
public:
	virtual ~renderIf() {};

	// Initializes renderer
	//
	// This should initialize the renderer (so it is capable to produce
	// display) with sane defaults, to be used in contexts where it is
	// not possible to know exact characteristics of the renderer.
	//
	// Should return false if the initialization is not possible. If the
	// renderer is already initialized, then it should re-initialize
	// (roughly equivalent to setting properties without delay).
	//
	// Properties should not be reset on init, rather it should attempt
	// to use them.
	//
	virtual bool init() = 0;

	// Pushes a scanline into the renderer
	//
	// lbuf is the contents of the scanline, can be expected to be 2048
	// elements long. Offset zero is at the end of the HSync pulse, and
	// normally 1820 elements follow, the value on PORTC (pixel data) in
	// each cycle.
	//
	// llen is the length of the line in cycles. Normally 1820. This may
	// be arbitrary depending on how buggy is the emulated code (so it is
	// NOT the length of lbuf which is at most 2048 elements!).
	//
	// lno is the line number, zero or one at the end of the VSync pulse,
	// incrementing by 2 afterwards. In progressive scan mode only odd
	// numbers are returned (normally 1 to 523 inclusive). Interlaced
	// rendering may be implemented later by returning even lines for the
	// second field (0 to 524 inclusive).
	//
	// hsync is the cycle in which the HSync pulse started, normally
	// on the end of the line. The width of the pulse is llen - hsync.
	//
	// vsync is the cycle in which the VSync pulse started (if any). If
	// there is no VSync activity, it equals llen. If VSync was already
	// active during the render of the line, it is 0.
	//
	// The rendering of the output should be driven entirely by this
	// function. Note that a buggy emulated code might result in not
	// calling this at all!
	//
	virtual void line(uint8 const* lbuf, auint llen, auint lno,
	                  auint hsync, auint vsync) = 0;

	// Set property
	//
	// Sets the given property to the given value, then re-initializes
	// the renderer. Return false if not succesful, this case the
	// renderer may fall back into uninitialized state.
	//
	// This function only re-initializes the renderer if it is already
	// initialized.
	//
	virtual bool setProp(auint prop, asint val) = 0;

	// Set property with optional delayed reinit
	//
	// Same like Set property, however with an additional parameter to
	// delay re-initialization. If it is set true, then the effect of the
	// property change might be delayed (until a new setProp call or an
	// init).
	//
	// This function may only re-initializes the renderer if it is already
	// initialized.
	//
	virtual bool setProp(auint prop, asint val, bool delay) = 0;

	// Get property
	//
	// Returns the value of a renderer property. When delayed output is
	// active, for the affected properties the return value is
	// implementation defined.
	//
	virtual asint getProp(auint prop) = 0;

	// Allows the renderer doing something when there is no render
	//
	// This function should be called less often than a normal picture
	// frame, to allow for the renderer doing something if there is no
	// signal (no line calls) at all. Normally if the signal comes all
	// right or with minor glitches the renderer can ignore these calls.
	// If the signal is completely absent or unsuitable, it may use this
	// to output some error report.
	//
	virtual void tick() = 0;

	// Sets status field
	//
	// Sets a status report string. Normally this is a window caption. The
	// string should be preserved across reinits.
	//
	virtual void setStatusStr(char const* str) = 0;

	// Returns a 0RGB line
	//
	// Extracts and returns a scanline of output. The returned pixels are
	// in 0x00RRGGBB format. Number of lines and pixel counts should be
	// expected according to the RENDERIF_N_HEIGHT and RENDERIF_N_WIDTH
	// constants in normal mode, and RENDERIF_D_HEIGHT and
	// RENDERIF_D_WIDTH in debug mode.
	//
	virtual void getLine(uint32* dest, auint lno) = 0;
	virtual void* getFrame(void) = 0;
	virtual void getPixelFormatString(char* pix_fmt) = 0;
};


#endif
