
Video Mode 52 - Developer's manual
==============================================================================




Introduction
------------------------------------------------------------------------------


Video Mode 52 is a 5 cycle / pixel palettized mode at 2bpp (4 colors) depth
within a scanline. It is capable to display at most 288 pixels horizontally
(36 tiles of 8 pixels width).

The 5 cycles / pixel figure produces slightly wide pixels, however for most
graphics design square pixels may be assumed.

Overall key features of the frame renderer are as follows:

- Row oriented rendering. Using a row selector, any row may appear on any
  physical scanline, allowing for arbitrary split-screen and horizontal scroll
  effects.

- Tile row (8 pixels tall) oriented logical layout. There are up to 32 tile
  rows accessible at any given time, each configurable independently of the
  others.

- Horizontal scrolling as X shift to the left by 0 to 7 pixels is available,
  along with arbitrary VRAM start positions.

- There are 4 palettes provided in a 16 byte array (4 x 4 colors), either can
  be selected for any row, and Color 0 and Color 1 may also be overridden for
  any line from scanline color tables.

- Attribute modes are provided (compile time option as these further modes
  take significant amount of ROM) in various configurations.

- Up to 224 scanlines height, configurable by the Uzebox kernel's
  SetRenderingParameters() function.

- The 256 tiles can be split at any point between ROM and RAM tiles.

- Up to 4 ROM tilesets may be used on a single screen.

Overall key features of the sprite engine are as follows:

- Works with 8 x 8 pixel sprite tiles of either 3 or 4 colors plus
  transparency. The latter uses specially formatted 24 byte sprite tiles.

- Blitter concept with background restoring: for rendering sprites, blits are
  to be called placing sprites on the canvas like if it was a regular
  framebuffer. RAM tile allocation and related tasks are carried out by the
  sprite engine internally. The blits can be cleared by a simple operation to
  start a new render.

- X and Y mirroring.

- RAM tile usage can be controlled allowing the use of any number of RAM
  tiles.

- Can perform blits over Attribute mode 0 and mode 1. It can cope with
  different tilesets on the same screen (allowing the use of more than 256 ROM
  tiles), and can use RAM tiles as well as targets (so it will blit normally
  over RAM tiles not allocated for sprites).

- Supports masking: the tile layer may partially cover sprite content.

- Parallax scrolling: Each tile row may have an individual X shift of 0 to 7
  pixel. Combined with an appropriate scrolling algorithm, this enables
  horizontally scrolling tile rows independently of each other with sprites
  over them.




Data formats
------------------------------------------------------------------------------


ROM 2bpp tiles and Sprite tiles
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A 2 bits per pixel tile takes 16 bytes. It is laid out in the following manner
where right numbers indicate the relative byte offset (decimal) and the left
number pair the bits used to represent the pixel: ::

    00:76 00:54 00:32 00:10 01:76 01:54 01:32 01:10
    02:76 02:54 02:32 02:10 03:76 03:54 03:32 03:10
    04:76 04:54 04:32 04:10 05:76 05:54 05:32 05:10
    06:76 06:54 06:32 06:10 07:76 07:54 07:32 07:10
    08:76 08:54 08:32 08:10 09:76 09:54 09:32 09:10
    10:76 10:54 10:32 10:10 11:76 11:54 11:32 11:10
    12:76 12:54 12:32 12:10 13:76 13:54 13:32 13:10
    14:76 14:54 14:32 14:10 15:76 15:54 15:32 15:10

Sprites always use color index 0 as transparent. As an example a single
colored sprite showing an oval could have the following data: ::

    0x0FU, 0xF0U,
    0x3CU, 0x3CU,
    0xF0U, 0x0FU,
    0xC0U, 0x03U,
    0xC0U, 0x03U,
    0xF0U, 0x0FU,
    0x3CU, 0x3CU,
    0x0FU, 0xF0U,

ROM tilesets can start at any 256 byte boundary.


Four color sprites
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Four color sprite tiles are 24 bytes, each sprite line taking 3 bytes. These 3
bytes are as follows:

- Byte 0: Left half pixels (like a normal 2bpp tile's left half)
- Byte 1: Right half pixels (like a normal 2bpp tile's right half)
- Byte 2: Transparency mask, sprite pixel shows where mask bit is 1.

The transparency mask is high bits corresponding to leftmost pixels.




Tile row modes overview
------------------------------------------------------------------------------


The mode of a row is selected by row descriptor structures, pointed by the
m52_rowdesc_addr pointer. There are up to 32 such structures, each specifying
the properties of an 8 pixels tall tile row.

One tile descriptor takes 4 bytes as follows (in C they are accessible through
the m52_rowdesc_t structure, note that there are appropriate defines for
access in videoMode52.h):

- byte 0: Video RAM address, low byte.
- byte 1: Video RAM address, high byte.
- byte 2: bits 0 - 2: X shift to the left (0 - 7 pixels).
- byte 2: bit 3: Disable sprite blitting on this row if set.
- byte 2: bits 4 - 5: Attribute mode selection.
- byte 2: bit 6: Enable Color 0 replacements using m52_col0_addr if set.
- byte 2: bit 7: Enable Color 1 replacements using m52_col1_addr if set.
- byte 3: bits 0 - 1: ROM tileset to use (one of the 4 available globally).
- byte 3: bits 2 - 3: Palette to use (one of the 4 available globally).
- byte 3: bits 4 - 7: Display width.

Attribute mode selection:

- 0: No attributes. A tile in VRAM is 1 byte: Tile index.

- 1: Color 0 attributes. A tile in VRAM is 2 bytes: Color 0, Tile index. Takes
  3 KBytes extra ROM.

- 2: Color 1,2,3 attributes. A tile in VRAM is 4 bytes: Tile index, Color 1,
  Color 2, Color 3. RAM tiles only. Takes 5 KBytes extra ROM.

- 3: Mirroring and Color 2,3 attributes, a tile in VRAM is 3 bytes: Tile
  index, Color 2, Color 3. Bit 7 of the Tile index is X mirror flag. RAM tiles
  only, tile positions 128 - 255 are available (RAM 0x0800 - 0x0FFF). Takes 9
  KBytes extra ROM.

An attribute mode is available only if it was compiled in. This can be
controlled by the M52_ENABLE_ATTR0, M52_ENABLE_ATTR123 and M52_ENABLE_ATTR23M
compile-time flags.

Display width settings:

- 0: 80 pixels (10 tiles)
- 1: 96 pixels (12 tiles)
- 2: 112 pixels (14 tiles)
- 3: 128 pixels (16 tiles)
- 4: 144 pixels (18 tiles)
- 5: 160 pixels (20 tiles)
- 6: 176 pixels (22 tiles)
- 7: 192 pixels (24 tiles)
- 8: 208 pixels (26 tiles)
- 9: 224 pixels (28 tiles)
- 10: 240 pixels (30 tiles)
- 11: 256 pixels (32 tiles)
- 12: 272 pixels (34 tiles)
- 13: 288 pixels (36 tiles, may be partially off-screen)
- 14: Reserved for 304 pixels (for similar higher resolution modes)
- 15: Reserved for 320 pixels (for similar higher resolution modes)

The maximal display width can be controlled by M52_TILES_MAX_H, which by
default is set to 34. It can be set to 32, 34 or 36. Asking for more tiles
reduces the amount of cycles available for the inline mixer.




Scanline logic
------------------------------------------------------------------------------


The rendering of the frame is broken up in scanlines, whose render may be
controlled individually.

Normally and at most the frame has 224 displayed lines, this figure can be
configured by the kernel's SetRenderingParameters() function. Giving less
lines for the display increases lines within VBlank which can be used to
perform more demanding tasks.

Each displayed line (physical scanline) can contain any logical scanline of
the 256 from the 32 configurable tile rows. This selection may be directed by
a split list.

This list uses byte pairs defining locations where the logical scanline
counter has to be re-loaded. Afterwards the logical scanline counter
increments by one on every line. The byte pairs are as follows:

- byte 0: Physical scanline to act on (0 - 223)
- byte 1: Logical scanline to set

The first byte is a Logical scanline to set (0 for physical scanline is
implicit). The list can be terminated by a byte 0 value which can not be
reached any more, such as zero or 255.




Colors
------------------------------------------------------------------------------


Normally, when using neither color replacements or attributes, the 4 colors of
a tile are taken from the global palette, one of the 4 color sets as specified
in the row's descriptor. Color replacements and attributes may affect colors
the following manner:

- Color 0: If Color 0 replacements are enabled, it is loaded from the
  appropriate entry of the replacement table. If Color 0 attribute mode is
  used, the attribute mode takes precedence over this.

- Color 1: If Color 1 replacements are enabled, it is loaded from the
  appropriate entry of the replacement table. If Color 1,2,3 attribute mode is
  used, the attribute mode takes precedence over this.

- Color 2: If Color 1,2,3 attribute mode or Mirroring & Color 2,3 attribute
  mode is used, the color is loaded from the attribute.

- Color 3: If Color 1,2,3 attribute mode or Mirroring & Color 2,3 attribute
  mode is used, the color is loaded from the attribute.

Color 0 attribute mode may be used with 3 color sprites to provide a more
diverse colored background to them.

Color 0 replacements (with the always available no-attributes mode) may be
used similarly to produce a gradient backdrop (for a sky effect).

Color 1,2,3 attribute mode and Mirroring & Color 2,3 attribute modes
optionally combined with Color 0 and Color 1 replacements may be useful mostly
to produce diverse still images or images with little animation.
