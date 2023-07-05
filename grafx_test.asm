[BITS 16]
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

;SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*TEST_SCREEN_H
SCALED_SCREEN_W		equ	0x20*SCALE_MULTIPLIER			;;320 / 10
SCALED_SCREEN_H		equ	0x14*SCALE_MULTIPLIER			;;200 / 10 
;TEST_SCREEN_H		equ 0x6			;;200 / 10 
OFFSET_SCREEN_H		equ SCALED_SCREEN_H*SCREEN_WIDTH
;OFFSET_SCREEN_H		equ TEST_SCREEN_H*SCREEN_WIDTH

;MBRSPRITE_W			equ	0x100							;;256
;MBRSPRITE_AREA		equ	0x7D00							;;320 / * MBRSPRITE_W
;MBR_SIZE			equ 0x200

NEWSPRITE_AREA		equ	0x2800*SCALE_MULTIPLIER			;;320 / * MBRSPRITE_W
VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;SCALE_MULTIPLIER	equ 4
SCALE_MULTIPLIER	equ 2
;******************************************************************************
;_start	PROC	NEAR ; masm
start:
	jmp MichelAngeBitmap

setup:
	;xor ax,ax
	;push ax
	;pop es
	;int 13h
	push cs
	pop es

;******************************************************************************
;	Read back from hard disk drive C: sector 13 (Michelange vx grafx payload)
;******************************************************************************
read_vxpaint_from_disk:
;	mov ax,0x0201
;	mov ch, 0
;	mov	cl, 0x6	;cylinder 0, sector 6
	;mov bx, grafx_routines
;	lea bx, grafx_routines
;	;mov dl, 80h	; unnec. bc DL should already be set to the correct drive
;	mov dh, 0
	;mov dx, 80h
;	int 13h
	;mov [MichelAngeBitmap], bx
;	jc backupbaibai
	pop bx	
	;mov ax,0x0205
	mov ax,0x020A
	mov ch, 0
	mov	cl, 0x7	;cylinder 0, sector 6
	;mov bx, MichelAngeTest
	;lea bx, MichelAngeBitmap
	mov dh, 0
	int 13h
	;jc backupbaibai
	;jmp grafx_routines
	jmp vga_init

backupbaibai:	
	mov	ax,4C00h		;terminate program
	int	21h

;grafx_routines equ $-setup+0x200
;	times 512-($-$$) db 0


;MichelAngeTest:
;	times 2560-($-$$) db 0



vga_init:
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
	mov	cx, SCALED_SCREEN_W
;	shl cx, 1
	shr cx, 1
	xor di, di
	paint_loop:
		push 	di
		push	cx
		mbr_paint:
			push cs
			pop ds
			lea si, MichelAngeBitmap
			mov bx, SCALED_SCREEN_MAX
			vga_mbr_y:
				push di
				mov dx, SCALED_SCREEN_W
				vga_mbr_x:
					mov ax, ds:[si]
					;mov ax, [si]
					or al, es:[di]
					add al, 0x1
					;add al, [randtimer]
					;add al, [randshiftnum]
					mov es:[di], al 
					;mov es:[di+2], al 
					inc si
					inc di
					;add di, 4
					dec dx
					jnz vga_mbr_x
				pop di
				add di, OFFSET_SCREEN_H
				dec bx
				jnz vga_mbr_y
			pop si
		pop		cx
		pop 	di
		add		di, SCALED_SCREEN_W
		dec 	cx
		jnz	paint_loop

rsvp:
	mov cx, greetz_len
	mov si, greetz
	push cs
	pop ds

welcome:
	mov al, [si]
	mov bh, 0
	;mov bl, $-randtimer
	mov bl, 0x0F
	mov ah, 0x0E
	int 0x10
	inc si
	dec cx
	jnz welcome
	jmp key_check

randtimercheck:
	mov cx, 2
	mov si, randtimer
	push cs
	pop ds
randtimerprint:
	mov al, [si]
	mov bh, 0
	;mov bl, $-randtimer
	mov bl, 0x0F
	mov ah, 0x0E
	int 0x10
	inc si
	dec cx
	jnz randtimerprint
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
	;;check if keypress is ESC
	;cmp	al, 1Bh
	cmp	al, 1
	jnz	baibai
	;jnz mbr_paint
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

MichelAngeBitmap:
	call setup
	times 2560 db 0
;	;dw 0
;	;times 10240-($-$$) db 0
;
