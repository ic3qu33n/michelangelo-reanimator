bits 16
org 0

;******************************************************************************
;	Read MBR from hard disk drive C:, Cylinder 0, Head 0, Sector 1
;	and save it to BUF at end of this code
;******************************************************************************
;copy_mbr:
;	mov ax, 0x201	;read one sector of disk
;	mov	cx, 1
;	mov dx, 0x80 	;from Side 0, drive C:
;	lea bx, BUF		;to buffer BUF in DS
;	int 13h





org 0x7c00

xor 	ax,ax
mov 	ds,ax

mov 	si,msg
cld

ch_loop:
	lodsb
	or 	al,al
	jz	hang
	mov	ah, 0x0E
	mov	bh, 0
	int 0x10
	jmp	ch_loop

hang:
	jmp BUF

msg	db 'Hello from the other side',13,10,0

BUF:	
	times 510-($-$$) db 0
	db 0x55
	db 0xAA
