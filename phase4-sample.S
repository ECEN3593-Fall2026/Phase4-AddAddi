    .section .text
    .globl _start

_start:  

addi x1, x0, 15
addi x2, x0, 0xF0
addi x3, x0,  -2048 # 0x800 
nop
nop
nop
nop
add x0, x1, x2
nop
nop
nop
nop
add x4, x1, x2
nop
nop
nop
nop
add x5, x2, x3
nop
nop
nop
nop
add x6, x4, x5
nop
nop
nop
nop
nop
nop
nop
nop
