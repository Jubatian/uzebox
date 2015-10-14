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


#ifndef SCREENSHOT_H
#define SCREENSHOT_H

#include <stdio.h>
#include "types.h"
#include "renderif.h"


// Generates a screenshot
//
// Produces a screenshot into the current directory using a renderer's
// getLine method. It keeps track of screenshot file names internally.
//
// Notes: Later this may be improved by adding support for different (such
// as PNG) file formats, path, etc, leaving this interface function as-is,
// adding other functions to set these.
//
void screenShot(renderIf* ren);

void writeFrame(renderIf* ren, FILE *fp);

#endif
