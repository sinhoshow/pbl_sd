.include "calls_system.s"

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

.macro printStr str strLen
	@ldr r0, =str
	@bl countLen
	@mov r2, r0 @ r0 is return from countLen
	mov r2, #\strLen
	mov r0, #1
	ldr r1, =str		
	mov r7, #7
	svc 0
.endm

.global countLen @ Allow other files to call this routine
countLen: push {r4-r5} @ Save the registers we use.
	mov r4, r1
@ The loop is until byte pointed to by r1 is non-zero
loop: ldrb r5, [r0], #1 @ load character and increment pointer
	@ If r5 > 'z' then goto cont
	cmp r5, #'z' @ is letter > 'z'?
	bgt cont
	@ Else if r5 < 'a' then goto end if
	cmp r5, #'a'
	blt cont @ goto to end if
cont: 
	cmp r5, #0 @ stop on hitting a null	character
	bne loop @ loop if character isn't null
	sub r0, r0, r4 @ get the length by subtracting the	pointers
	pop {r4-r5} @ restore the register we use.
	bx ls @ return to caller


.macro mapMem
