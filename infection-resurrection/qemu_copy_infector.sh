#********************************************************************
#	This is a quick+dirty script for copying files from your 
#	 working dir to a virtual disk image for working w in QEMU 
#	(or equiv)
#	because maybe you have a virtual disk formatted with FreeDOS 1.3
#	and you just want to transfer over your nice lil vx to that img
#	
#	I kept typing these lines into the terminal over and over and
#	that annoyed me, so I made a shell script out it
#	This is for a pretty specific use-case (see above bb)
#	but the workflow may have some crossover with other projects
#
#
#********************************************************************
TESTDISK=$1
#ASMfile=$2
#BIN2copy=$3
BIN2copy=$2
TESTDIR=$(pwd)
#********************************************************************
#	Assumes you have already created a directory in the tmp folder, 
#	to serve as a mountpoint for the disk image
#	Otherwise do the following:
# 	sudo mkdir /tmp/{dos_disk_img}/
#********************************************************************

#nasm -f bin -o grafx_setup.com grafx_setup.asm                                                            
##nasm -f bin -o $BIN2copy $ASMfile                                                            

##sudo umount is really not necessary but I do it incase the disk image is still mounted
sudo umount /tmp/dos

#sudo mount -o loop,offset=32256 newdos_clone0.img /tmp/dos    
sudo mount -o loop,offset=32256 $TESTDISK /tmp/dos    

cd /tmp/dos
# optional traversal into subdir; my virtual disk is formatted w freedos
# and I like using that dir for this purpose
# adjust as you see fit
cd FREEDOS

##new file name should be decriptive but < 8 chars bc filename len limits bb
#qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img  
#sudo cp ~/Desktop/b00tkit_testing/grafx_test.com gtest.com
sudo cp $TESTDIR/$BIN2copy infector.com
#cd ~/Desktop/b00tkit_testing
cd $TESTDIR
#Here the sudo umount is absolutely essential
# do not run the disk in QEMU if the disk image is still mountedqemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img  
#don't make me sad. don't do it.
## sudo umount is important bb
# tysm 
sudo umount /tmp/dos
 
#
##qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img   
#qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda newdos_clone0.img
qemu-system-i386 -m 16 -device cirrus-vga -display gtk -drive file=$TESTDISK,format=raw,index=0,media=disk
