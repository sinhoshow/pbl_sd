.include "calls_system.s"

.macro openFile fileName, flags
	ldr r4, =\flags
	ldr r4, [r4]
	ldr r0, =\fileName
	@printStr strtst, strtstLen
	mov r1, r4
	@printStr strtst, strtstLen
	ldr r4, =S_RDWR_file
	ldr r4, [r4]
	mov r2, r4@ RW access rights
	
	mov r7, #sys_open
	svc 0
.endm

.macro readFile fd, buffer, length
	mov r0, \fd @ file descriptor
	ldr r1, =\buffer
	mov r2, #\length
	mov r7, #sys_read
	svc 0
.endm

.macro writeFile fd, buffer, length
	mov r0, \fd @ file descriptor
	ldr r1, =\buffer
	mov r2, \length
	mov r7, #sys_write
	svc 0
.endm

.macro flushClose fd
	@fsync syscall
	mov r0, \fd
	mov r7, #sys_fsync
	svc 0
	@close syscall
	mov r0, \fd
	mov r7, #sys_close
	svc 0
.endm

.macro printStr stringtst, strLen
	@ldr r0, =str
	@bl countLen
	@mov r2, r0 @ r0 is return from countLen
	ldr r2, =\strLen
    ldr r2, [r2]
	mov r0, #1
	ldr r1, =\stringtst		
	mov r7, #sys_write
	svc 0
.endm

@ .global countLen @ Allow other files to call this routine
@ countLen: push {r4-r5} @ Save the registers we use.
@ 	mov r4, r1
@ @ The loop is until byte pointed to by r1 is non-zero
@ loop: ldrb r5, [r0], #1 @ load character and increment pointer
@ 	@ If r5 > 'z' then goto cont
@ 	cmp r5, #'z' @ is letter > 'z'?
@ 	bgt cont
@ 	@ Else if r5 < 'a' then goto end if
@ 	cmp r5, #'a'
@ 	blt cont @ goto to end if
@ cont: 
@ 	cmp r5, #0 @ stop on hitting a null	character
@ 	bne loop @ loop if character isn't null
@ 	sub r0, r0, r4 @ get the length by subtracting the	pointers
@ 	pop {r4-r5} @ restore the register we use.
@ 	bx lr @ return to caller
.data
strtst: .asciz "Abrindo arquivo...\n"
strtstLen: .word .-strtst
O_RDONLY_file: .word 0
O_WRONLY_file: .word 1
O_CREAT_file: .word 0100
S_RDWR_file: .word 0666
