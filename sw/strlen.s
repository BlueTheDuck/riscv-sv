.section .text
.global strlen
strlen:
        mv      a4,a0
        lbu     a5,0(a0)
        li      a0,0
        beq     a5,zero,.L1
.L2:
        addi    a0,a0,1
        add     a5,a4,a0
        lbu     a5,0(a5)
        bne     a5,zero,.L2
.L1:
        ret
