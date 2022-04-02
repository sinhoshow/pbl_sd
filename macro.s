	.include "sys_open.s"
	.equ O_RDONLY, 0
	.equ O_WRONLY, 1
	.equ O_CREAT, 0100
	.equ S_RDWR, 0666
	.macro openFile fileName, flags
		ldr r0, =\fileName
		mov r1, #\flags
		mov r2, #S_RDWR @ RW access rights
		mov r7, #sys_open
		svc 0
	.endm
