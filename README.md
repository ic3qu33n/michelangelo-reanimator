# Michelangelo REanimator

This is the repo for the Michelangelo REanimator bootkit -- this season's hot+fresh new legacy BIOS bootkit 
[a new take on the classic Michelangelo bootkit of the 1990s, itself a variation of the Stoned bootkit.]
and the associated materials for my REcon 2023 talk.

Talk slides are in the REcon2023Slides folder (obv)

**This repo is a work in progress, so please bear w me while I continue to organize and document the various pieces.

Initial notes on bootkit debugging are below.
They will be moved elsewhere at some point 
(to a coherent singular document summarizing my bootkit dev/debugging methodology perhaps??)
For now, enjoy the chaos. 
If you have questions/comments/concerns/lots of emo feelings that are stirred up by the beauty that is 16bit x86 asm 
(honey believe me, I know the feeling!), then feel free to hit me up on one of the myriad internet forums I frequent.
If you found this repo, you know where to find me.


xoxo
ic3qu33n



# ******** Bootkit Debugging ******* #
# 
#

For debugging x86 bootkits on an aarch64 machine refer to the various techniques outlined below
For debugging setups on other machines (i.e. testing on a machine with an x86 processor), refer to the Resources section

In one terminal window (I recommend running these two commands in separate terminal windows and not a single window running
a terminal multiplexer, due to how gdb is already going to be using a split layout in one window).
gdb-multiarch -q --nh -ex 'set architecture i8086' -ex 'file dos_rip.img' -ex 'target remote localhost:1234' -ex 'layout split' -ex 'layout regs'


In another terminal window (again I'm recommending to run these in two different windows and not a split paneled tmux session,
but far be it from me to tell you how to live your life. If you like that Mondrian kd-tree-style layout of a terminal window
with nested bifurcations, then by all means, live ur truth bb.)
qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img -s -S
qemu-system-i386 -m 16 -k en-us -rtc base=localtime -device cirrus-vga -display gtk -hda dos_rip.img -s -S
python3 infect_mbr_stoned.py -mbr michelange1ststage.mbr -vxpaint michelange2ndstage.bin  -diskimg dos_rip.img -sector 0 -vxpaintsector 2
