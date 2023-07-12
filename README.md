# Michelangelo REanimator

This is the repo for the Michelangelo REanimator bootkit -- this season's hot+fresh new legacy BIOS bootkit 
[a new take on the classic Michelangelo bootkit of the 1990s, itself a variation of the Stoned bootkit.]
and the associated materials for my REcon 2023 talk.

Talk slides are in the REcon2023Slides folder (obv)

**This repo is a work in progress, so please bear w me while I continue to organize and document the various pieces.

Initial notes on bootkit debugging are below.
They will be moved elsewhere at some point 
(to a coherent singular document summarizing my bootkit dev/debugging methodology perhaps??)
For now, enjoy the chaos. 
If you have questions/comments/concerns/lots of emo feelings that are stirred up by the beauty that is 16bit x86 asm 
(honey believe me, I know the feeling!), then feel free to hit me up on one of the myriad internet forums I frequent.
If you found this repo, you know where to find me.


xoxo
ic3qu33n

#****

Michelangelo REanimator
Bootkit Technical Specs

![A screenshot of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image is a range of pinks and blues, but each sprite tile has a slightly altered subset of colors from that palette.](./vx_art_images/michelangelo-reanimator-demo-screenshot-3.png)


![A screenshot of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image is a range of shades that range from reds and pinks to yellow and green to dark blues; nearly the entire rainbow can be seen in pixels sprinkled throughout; , but each sprite tile has a slightly altered subset of colors from that palette.](./vx_art_images/michelangelo-reanimator-demo-screenshot-0.png)


![A screenshot of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image is a range of shades, primarily dark blue, olive green, magenta and pinks, yellow and some light green;, but each sprite tile has a slightly altered subset of colors from that palette.](./vx_art_images/michelangelo-reanimator-demo-screenshot-1.png)

In many bootkits that target MBRs, there will be a routine in the virus for copying the partition table
of the original MBR to offset 0x1BE in the viral MBR. This ensures  that the viral MBR is still a valid MBR
(i.e. correct magic bytes/placement of data structures at specified offsts, etc.) 

This payload skips this step to save a few bytes and leans on the fact that 
a standard partition table is created when installing FreeDOS 1.3 onto a virtual hard drive image.
So, payload_part1 already contains a copy of the partition table
Saving a copy of this standard FreeDOS partition table in the viral MBR ensures that it meets the proper checks
The viral MBR does, of course, jump back to the original MBR, which provides the saved copy 
of whatever partition table it originally contained and its routines for loading the OS.
It's almost like nothing ever happened...
 


The payload is split into two parts because I wanted to use a graphical payload that has 
a size of 10240 bytes. The MBR is limited to 512 bytes (the size of a sector), but an MBR's code
can very well include a routine for loading a second stage bootloader from disk (of greater size,
limited by the number of free sectors on disk and the amount of available memory in RAM;) into RAM,
The second stage bootloader will proceed to do its thing, provided that the following holds:
1. There is adequate space in RAM available for the loaded sectors of the viral second stage loader
to be mapped to 
2. The memory range where the second stage bootloader is mapped does not overlap any critical regions
in memory (i.e. the IVT in the first 0x400 bytes, the BIOS Data Area in 0x5000-0x6000, etc.)
3. trivially, that the first stage bootloader implements a proper routine to load, and jump to, 
the second stage bootloader in memory.

So that's what this payload does:
It sets up the necessary stack frame for an MBR/boot sector, 
it loads the second stage bootloader from disk; the second stage bootloader is 21 sectors (10752 bytes)
Of the 10752 bytes of the second stage loader, only the first of that set of retrieved sectors 
(the first 512b of the second stage loader file)  contains code; 
the remaining bytes are occupied by the graphics payload image (the art == 10240 bytes)
After loading those 21 sectors, the first stage loader copies them to a designated region in RAM 
(at address 0x90000, or 0x900:0000) and jumps to it

The second stage of the payload does the following:
Displays a graphical payload of one of my drawings. 

Technically the graphical payload is a result of the following:
1. I scanned a drawing I had made, which was a pen+ink study of the "Pieta" sculpture by Michelangelo
2. I wrote a Python script to downsample the image file so that the resulting image resolution 
was (320// some_factor) * (200 // some_factor) * diff_factor
the factor I chose was 10 and 4; the reasons for which are outlined in my REcon 2023 talk
The resulting 128x80 image (1 byte == 1 pixel since I use VGA mode 13h, 
VGA mode 13h = 320x200x256 VGA mode)
I converted the image to its bytes (.toBytes() has a nice moment) and then appended the
resultant sequences of bytes to the second stage payload

The second stage payload then uses various routines to load the bytes of the image,
perform various bitwise manipulation operations on the bytes to modify the pixel values
on each iteration of the animation sequence for the graphical payload rendering

The second stage payload implements a custome palette, using polymorphism to change this palette on each iteration
The code for the palette routine was based heavily on that of two palettes by Rrrola 
;******************************************************************************
;	Palette routine in this bootkit was adapted from the following 2 palettes:
	"Symetrie" and "Atraktor" by Rrrola
;	 https://abaddon.hu/256b/colors.html 
;	Their palettes are gorgeous. Go check them out.
;******************************************************************************



[A screenshot of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image is a range of most pastel shades (orange, pink and green), on a background of cerulean blue, with accents of dark purple and green, but each sprite tile has a slightly altered subset of colors from that palette.][./vx_art_images/michelangelo-reanimator-demo-screenshot-2.png]

The second stage payload also does the following:
-uses polymorphism to ensure that the graphical payload mutates slightly on each iteration
-loads the original MBR from the 3rd sector on disk (where it had been saved during viral infection)
maps it into memory at 0x7c00  and jumps to it


More notes on other bootkit features to follow.

Here are some demo videos of the bootkit after it has infected a target disk.

*Warning, mild flashing lights warning on both videos.*


![A video of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image changes each frame, so the result is that the animation of the sprite shifts colors; the effect is somewhat of a trip, between iridescent waterfall of holy image and shimmering mirage in the desert.](./vx-art-images/michelangelo-reanimator-demo-vid-0.mov)

![A video of the graphics payload displayed by the Michelangelo REanimator bootkit, a sprite (pixelated image) is displayed in a repeated pattern across the screen; the sprite is a drawing of a study of Michelangeo's Pieta, thus the image is of a woman (Mary) holding the body of her son (Jesus); color palette of the entire image changes each frame, so the result is that the animation of the sprite shifts colors; the effect is somewhat of a trip, between iridescent waterfall of holy image and shimmering mirage in the desert.](./vx-art-images/michelangelo-reanimator-demo-vid-1.mov)




# ******** Bootkit Debugging ******* #
# 
#

For debugging x86 bootkits on an aarch64 machine refer to the various techniques outlined below  
For debugging setups on other machines (i.e. testing on a machine with an x86 processor), refer to the Resources section  
  
In one terminal window (I recommend running these two commands in separate terminal windows and not a single window running
a terminal multiplexer, due to how gdb is already going to be using a split layout in one window).   
```
gdb-multiarch -q --nh -ex 'set architecture i8086' -ex 'file dos_rip.img' -ex 'target remote localhost:1234' -ex 'layout split' -ex 'layout regs'  
```  
  
In another terminal window (again I'm recommending to run these in two different windows and not a split paneled tmux session,
but far be it from me to tell you how to live your life. If you like that Mondrian kd-tree-style layout of a terminal window
with nested bifurcations, then by all means, live ur truth bb.)  

```  
qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img -s -S   
qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img -s -S   
python3 infect_mbr_stoned.py -mbr michelange1ststage.mbr -vxpaint michelange2ndstage.bin  -diskimg dos_rip.img -sector 0 -vxpaintsector 2   
```
