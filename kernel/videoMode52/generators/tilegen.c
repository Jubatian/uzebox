/*
**  Converts GIMP header to Uzebox Mode 52 tiles C source.
**
**  By Sandor Zsuga (Jubatian)
**
**  Licensed under GNU General Public License version 3.
**
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
**  ---
**
**  The input image must be n x 8 (width x height) where 'n' is a multiple of
**  8. It must have 4 colors.
**
**  Produces result onto standard output, redirect into a ".c" file to get it
**  proper.
*/



/*  The GIMP header to use */
#include "tileset.h"


#include <stdio.h>
#include <stdlib.h>



int main(void)
{
 unsigned int  tcnt = width / 8U;
 unsigned int  sp;
 unsigned int  i;
 unsigned int  j;
 unsigned char c;

 /* Basic tests */

 if ((width % 8U) != 0U){
  fprintf(stderr, "Input width must be a multiple of 8!\n");
  return 1;
 }
 if ((height) != 8U){
  fprintf(stderr, "Input height must be 8!\n");
  return 1;
 }
 if (tcnt > 256U){
  fprintf(stderr, "Input must have 256 or less tiles!\n");
  return 1;
 }


 /* Start generating the C file */

 printf("/*\n");
 printf("** Mode 52 Tileset of %u tiles\n", tcnt);
 printf("*/\n");
 printf("\n");
 printf("M52_ROMTILESET_PRE unsigned char tileset[%uU * 16U] M52_ROMTILESET_POST = {\n", tcnt);


 /* Generate tile rows */

 for (i = 0U; i < tcnt; i ++ ){

  sp = (i * 8U);

  for (j = 0U; j < 8U; j ++){
   c  = ((header_data[sp + 0U] & 3U) << 6) |
        ((header_data[sp + 1U] & 3U) << 4) |
        ((header_data[sp + 2U] & 3U) << 2) |
        ((header_data[sp + 3U] & 3U)     );
   printf(" 0x%02XU,", c);
   c  = ((header_data[sp + 4U] & 3U) << 6) |
        ((header_data[sp + 5U] & 3U) << 4) |
        ((header_data[sp + 6U] & 3U) << 2) |
        ((header_data[sp + 7U] & 3U)     );
   printf(" 0x%02XU,", c);
   sp += width;
  }

  printf("\n");

 }

 printf("};\n");


 return 0;
}
