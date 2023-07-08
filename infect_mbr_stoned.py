#!/usr/bin/python

import re, sys, os
import argparse

#####################################################################
#	infect writes a malicious MBR to the disk image
#	created with bximage
#	
#	##Code based on the script from "Rootkits and Bootkits"(Page 213)
#	written by Alex Matrosov, Eugene Rodionov and Sergey Bratus
#
#####################################################################

def vxinfect(mal_mbr, disk_img, sector_number):
	with open(mal_mbr, 'rb') as mbr_file:
		mbr=mbr_file.read()
		with open(disk_img, "r+b") as disk_img_file:
			#disk_img_file.seek(0)
			diskadr_offset=sector_number*512
			disk_img_file.seek(diskadr_offset)
			disk_img_file.write(mbr)
	return 0

def vxinfect_this_time_with_feeling(mal_mbr, disk_img, sector_number, og_mbr, og_mbr_sector_number, vxpaint, vxsector_number):
	with open(mal_mbr, 'rb') as mbr_file:
		mbr=mbr_file.read()
		with open(og_mbr, 'rb') as ogmbr_file:
			ogmbr=ogmbr_file.read()
			with open(vxpaint, 'rb') as vxpaintfile:
				vxpainting=vxpaintfile.read()
				with open(disk_img, "w+b") as disk_img_file:
					#disk_img_file.seek(0)
					diskadr_offset=sector_number*512
					disk_img_file.seek(diskadr_offset)
					disk_img_file.write(mbr)
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
	
	if vx_paint == None:
		infect(mal_mbr, disk_img, sector)

	else:
		#vxinfect_this_time_with_feeling(mal_mbr, disk_img, sector, vx_paint, vx_paintsector)
		vxinfect_this_time_with_feeling(mal_mbr, disk_img, sector, og_mbr, og_mbr_sector, vx_paint, vx_paintsector)
		
