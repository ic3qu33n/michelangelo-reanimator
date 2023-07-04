bits 16
;.286			;masm specific
;.MODEL TINY		;masm specific

;******************************************************************************
;	COM Program that manipulates pixel values of command prompt 
;	by writing directly to VGA buffer
;	
;	To be used in DOSBOX (or similar) MS-DOS Emulator program 
;	Must be compiled with link16.exe (MASM32 preferably) 
;
;******************************************************************************

.CODE:
	org 100h

;******************************************************************************

SCREEN_MAX			equ	320*200
SCREEN_WIDTH		equ	0x140							;;320
SCREEN_HEIGHT		equ	0xC8							;;200
;SCALED_SCREEN_MAX	equ	0x280*SCALE_MULTIPLIER
SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*SCALED_SCREEN_H
SCALED_SCREEN_W		equ	0x20*SCALE_MULTIPLIER			;;320 / 10
SCALED_SCREEN_H		equ	0x14*SCALE_MULTIPLIER			;;200 / 10 
OFFSET_SCREEN_H		equ SCALED_SCREEN_H*SCREEN_WIDTH
;MBRSPRITE_W			equ	0x100							;;256
;MBRSPRITE_AREA		equ	0x7D00							;;320 / * MBRSPRITE_W
NEWSPRITE_AREA		equ	0x2800*SCALE_MULTIPLIER			;;320 / * MBRSPRITE_W
VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;MBR_SIZE			equ 0x200
SCALE_MULTIPLIER	equ 4
;SCALE_MULTIPLIER	equ 2
;******************************************************************************
;_start	PROC	NEAR ; masm

;******************************************************************************
;	Write back to hard disk drive C: sector 1 (MBR)
;******************************************************************************
;copy_vxpaint_to_disk:
;	;mov ax, 0
;	;push ax
;	;pop es
;	;int 13h
;	push cs
;	pop es
;	
;	;mov ax,0x0305
;	mov ax, 0x0301	;1 sector for code, 5 sectors for image bitmap
;	mov ch, 0
;	mov	cl, 0x6	;cylinder 0, sector 13 (0xD)
;	;mov dh, 0
;	;mov dx, 80h
;	mov dh, 8h
;	;lea bx, MichelAngeBitmap 
;	;lea bx, MichelAngeTest 
;	mov bx, VXgrafx 
;	int 13h
;	
;	mov ax, 0x030A	;1 sector for code, 5 sectors for image bitmap
;	mov ch, 0
;	mov	cl, 0x7	;cylinder 0, sector 13 (0xD)
;	mov dh, 0
;	lea bx, MichelAngeBitmap 
;	int 13h
;;******************************************************************************
;;
;;	Terminates program (function 4Ch,int21h)
;;
;;******************************************************************************
;setupbaibai:	
;	mov	ax,4C00h		;terminate program
;	int	21h

VXgrafx:
	jmp MichelAngeBitmap
vga_init:
	pop si
	push si
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
	pop es
	pop ax
	jmp paint_setup

set_pal:
	salc				;set carry flag in al, if carry flag set, al=0
	mov	dx,VGA_PAL_INDEX	;
	out	dx, al
	inc	dx
	pal_1:
		or	ax,0000111100110011b
		push	ax
		shr	ax, 10
		out	dx,al
		mul	al
		shr	ax, 6
		out 	dx,al
		pop	ax
		out	dx,al
		inc	ax
		jnz	pal_1


paint_setup:
	pop si
	mov cx, SCALED_SCREEN_W
	xor di, di
	paint_loop:
		push 	di
		push	cx
		mbr_paint:
			push si
			push cs
			pop ds
			;lea si, MichelAngeBitmap
			mov bx, SCALED_SCREEN_MAX
			vga_mbr_y:
				push di
				mov dx, SCALED_SCREEN_W
				vga_mbr_x:
					;lodsb
					mov ax, ds:[si]
					or al, es:[di]
					add al, 0x01
					mov es:[di], al 
					;mov es:[di+2], al 
					inc si
					inc di
					;add di, 4
					dec dx
					jnz vga_mbr_x
				pop di
				;add di, OFFSET_SCREEN_H
				add di, SCREEN_WIDTH
				dec bx
				jnz vga_mbr_y
			pop si
		pop		cx
		pop 	di
		;add		di, SCALED_SCREEN_W
		add		di, NEWSPRITE_AREA
		dec 	cx
	;	jnz	paint_loop

rsvp:
	mov cx, greetz_len
	mov si, greetz
	push cs
	pop ds

welcome:
	mov al, [si]
	mov bh, 0
	mov bl, 0x0F
	mov ah, 0x0E
	int 0x10
	inc si
	dec cx
	jnz welcome
	jmp key_check

;******************************************************************************
;
;	Reads char from buffer (function 0h,int16h)
; 	Char returned in al
; 	If char in al == 0x1b (ESC) then terminate program
;	Else, continue VGA *~pretty picture~* loop
;
;******************************************************************************
key_check:
	xor	ax,ax
	int	16h
	;;check if keypress
	cmp	al, 1
	jnz	baibai
;******************************************************************************
;
;	Terminates program (function 4Ch,int21h)
;
;******************************************************************************
baibai:	
	mov	ax,4C00h		;terminate program
	int	21h

greetz:
	db "u know u luv me.", 0Dh, 0Ah
	db "xoxo", 0Dh, 0Ah
	db "ic3qu33n", 0Dh, 0Ah

greetz_len	equ $-greetz
	
randtimer:
	db 0

grafx_end:
	times 512-($-$$) db 0


