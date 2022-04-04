@@@ Raspberry Pi devices
@@@ -----------------------------------------------------------
@@@ This file provides a function "IO_init" that will
@@@ map some devices into the user program’s memory
@@@ space. Pointers to the devices are stored in
@@@ global variables, and the user program can then
@@@ use those pointers to access the device registers.
@@@ -----------------------------------------------------------
	.include "macros.s"
    .data
@@@ -----------------------------------------------------------
@@@ The following global variables will hold the addresses of
@@@ the devices that can be accessed directly after IO_init
@@@ has been called.
    .global gpiobase
gpiobase: .word 0
    .global uartbase
uartbase: .word 0    

@@@ These are the addresses for the I/O devices (after
@@@ the firmware boot code has remapped them).
    .equ PERI_BASE, 0x20000000 @ start of all devices
@@ Base Physical Address of the GPIO registers
    .equ GPIO_BASE, (PERI_BASE + 0x200000)
@@ Base Physical Address of the UART 0 device
    .equ UART0_BASE,(PERI_BASE + 0x201000)

    .equ MAP_FAILED,-1
    .equ MAP_SHARED, 1
    .equ PROT_READ, 1
    .equ PROT_WRITE, 2
    .equ BLOCK_SIZE,(4*1024)
@@ some constants from fcntl.h
    .equ O_RDONLY, 00000000
    .equ O_WRONLY, 00000001
    .equ O_RDWR, 00000002
    .equ O_CREAT, 00000100
    .equ O_EXCL, 00000200
    .equ O_NOCTTY, 00000400
    .equ O_TRUNC, 00001000
    .equ O_APPEND, 00002000
    .equ O_NONBLOCK, 00004000
    .equ O_NDELAY, O_NONBLOCK
    .equ O_SYNC, 00010000
    .equ O_FSYNC, O_SYNC
    .equ O_ASYNC, 00020000

memdev: .asciz "/dev/mem"
successstr: .asciz "Successfully opened /dev/mem\n"
successstrLen: .word .-successstr
mappedstr: .asciz "Mapped %s device at 0x%08X\n"
mappedstrLen: .word .-mappedstr
openfailed: .asciz "IO_init: failed to open /dev/mem: "
openfailedLen: .word .-openfailed
mapfailedmsg: .asciz "IO_init: mmap of %s failed: "
mapfailedmsgLen: .word .-mapfailedmsg
gpiostr: .asciz "GPIO"
uart0str: .asciz "UART0"
inituart: .asciz "Inicializando a uart\n"
inituartLen: .word .-inituart
sendChar: .asciz "Enviando char\n"
sendCharLen: .word .-sendChar
getChar: .asciz "Recebendo char\n"
getCharLen: .word .-getChar
charTest: .asciz "a"

    .text
@@@ -----------------------------------------------------------
@@@ IO_init() maps devices into memory space and stores their
@@@ addresses in global variables.
@@@ -----------------------------------------------------------
    .global _start
_start:
    stmfd sp!,{r4,r5,lr}
    @@ Try to open /dev/mem
	ldr r6, =memdev @ load address of "/dev/mem"
    ldr r1,=(O_RDWR + O_SYNC) @ set up flags
    openFile    memdev, S_RDWR @ call the open syscall
    cmp r0,#0 @ check result
    bge init_opened @ if open failed,
    @ldr r0,=openfailed @ print message and exit
    @bl printf
    printStr openfailed openfailedLen
    bl __errno_location
    ldr r0, [r0]
    bl strerror
    bl perror
    mov r0,#0 @ return 0 for failure
    b init_exit

init_opened:
    @@ Open succeeded. Now map the devices
    mov r4,r0 @ move file descriptor to r4
    @ldr r0,=successstr
    @bl printf
    printStr successstr successstrLen
    
    @@ Map the GPIO device
    mov r0,r4 @ move file descriptor to r4
    ldr r1,=GPIO_BASE @ address of device in memory
    bl trymap
    cmp r0,#MAP_FAILED
    ldrne r1,=gpiobase @ if succeeded, load pointer
    strne r0,[r1] @ if succeeded, store value
    ldreq r1,=gpiostr @ if failed, load pointer to string
    beq map_failed_exit @ if failed, print message
    mov r2,r1
    ldr r2,[r2]
    @ldr r0,=mappedstr @ print success message
    ldr r1,=gpiostr
    @bl printf
    printStr mappedstr mappedstrLen
    
    @@ Map the UART0 device
    mov r0,r4 @ move file descriptor to r4
    ldr r1,=UART0_BASE @ address of device in memory
    bl trymap
    cmp r0,#MAP_FAILED
    ldrne r1,=uartbase @ if succeeded, load pointer
    strne r0,[r1] @ if succeeded, store value
    ldreq r1,=uart0str @ if failed, load pointer to string
    beq map_failed_exit @ if failed, print message
    mov r2,r1
    ldr r2,[r2]
    @ldr r0,=mappedstr @ print success message
    ldr r1,=uart0str
    @bl printf
    printStr mappedstr mappedstrLen
    
    
    @@ All mmaps have succeeded.
    @@ Close file and return 1 for success
    mov r5,#1
    b init_close

map_failed_exit:
    @@ At least one mmap failed. Print error,
    @@ unmap everything and return
    @ ldr r0,=mapfailedmsg
    @ bl printf
    printStr mapfailedmsg mapfailedmsgLen
    bl __errno_location
    ldr r0, [r0, #0]
    bl strerror
    bl perror
    bl IO_close
    mov r0,#0

init_close:
    mov r0,r4 @ close /dev/mem
    bl close
    bl UART_init     

init_exit:
    ldmfd sp!,{r4,r5,pc} @ return
    
@@@ -----------------------------------------------------------
@@@ trymap(int fd, unsigned offset) Calls mmap.
trymap: 
    stmfd sp!,{r5-r7,lr}
    mov r5,r1 @ copy address to r5
    mov r7,#0xFF @ set up a mask for aligning
    orr r7,#0xF00
    and r6,r5,r7 @ get offset from page boundary
    bic r1,r5,r7 @ align phys addr to page boundary
    stmfd sp!,{r0,r1} @ push last two params for mmap
    mov r0,#0 @ let kernel choose virt address
    mov r1,#BLOCK_SIZE
    mov r2,#(PROT_READ + PROT_WRITE)
    mov r3,#MAP_SHARED
    mov r7, #sys_mmap2 @ mmap2 service num
    svc 0 @ call service
    @bl mmap
    add sp,sp,#8 @ pop params from stack
    cmp r0,#-1
    addne r0,r0,r6 @ add offset from page boundary
    ldmfd sp!,{r5-r7,pc}

    @@@ -----------------------------------------------------------
    @@@ IO_close unmaps all of the devices
    .global IO_close
IO_close:
    stmfd sp!,{r4,r5,lr}
    ldr r4,=gpiobase @ get address of first pointer
    mov r5,#4 @ there are 4 pointers

IO_closeloop:
    ldr r0,[r4] @ load address of device
    mov r1,#BLOCK_SIZE
    cmp r0,#0
    blgt munmap @ unmap it
    mov r0,#0
    str r0,[r4],#4 @ store and increment
    subs r5,r5,#1
    bgt IO_closeloop
    ldmfd sp!,{r4,r5,pc}

@@ offsets to the UART registers
    .equ UART_DR, 0x00 @ data register
    .equ UART_RSRECR, 0x04 @ Receive Status/Error clear
    .equ UART_FR, 0x18 @ flag register
    .equ UART_ILPR, 0x20 @ not used
    .equ UART_IBRD, 0x24 @ integer baud rate divisor
    .equ UART_FBRD, 0x28 @ fractional baud rate divisor
    .equ UART_LCRH, 0x2C @ line control register
    .equ UART_CR, 0x30 @ control register
    .equ UART_IFLS, 0x34 @ interrupt FIFO level select
    .equ UART_IMSC, 0x38 @ Interrupt mask set clear
    .equ UART_RIS, 0x3C @ raw interrupt status
    .equ UART_MIS, 0x40 @ masked interrupt status
    .equ UART_ICR, 0x44 @ interrupt clear register
    .equ UART_DMACR, 0x48 @ DMA control register
    .equ UART_ITCR, 0x80 @ test control register
    .equ UART_ITIP, 0x84 @ integration test input
    .equ UART_ITOP, 0x88 @ integration test output
    .equ UART_TDR, 0x8C @ test data register

    @@ error condition bits when reading the DR (data register)
    .equ UART_OE, (1<<11) @ overrun error bit
    .equ UART_BE, (1<<10) @ break error bit
    .equ UART_PE, (1<<9) @ parity error bit
    .equ UART_FE, (1<<8 ) @ framing error bit

    @@ Bits for the FR (flags register)
    .equ UART_RI, (1<<8) @ Unsupported
    .equ UART_TXFE, (1<<7) @ Transmit FIFO empty
    .equ UART_RXFF, (1<<6) @ Receive FIFO full
    .equ UART_TXFF, (1<<5) @ Transmit FIFO full
    .equ UART_RXFE, (1<<4) @ Receive FIFO empty
    .equ UART_BUSY, (1<<3) @ UART is busy xmitting
    .equ UART_DCD, (1<<2) @ Unsupported
    .equ UART_DSR, (1<<1) @ Unsupported
    .equ UART_CTS, (1<<0) @ Clear to send

    @@ Bits for the LCRH (line control register)
    .equ UART_SPS, (1<<7) @ enable stick parity
    .equ UART_WLEN1, (1<<6) @ MSB of word length
    .equ UART_WLEN0, (1<<5) @ LSB of word length
    .equ UART_FEN, (1<<4) @ Enable FIFOs
    .equ UART_STP2, (1<<3) @ Use 2 stop bits
    .equ UART_EPS, (1<<2) @ Even parity select
    .equ UART_PEN, (1<<1) @ Enable parity
    .equ UART_BRK, (1<<0) @ Send break

    @@ Bits for the CR (control register)
    .equ UART_CTSEN, (1<<15) @ Enable CTS
    .equ UART_RTSEN, (1<<14) @ Enable RTS
    .equ UART_OUT2, (1<<13) @ Unsupported
    .equ UART_OUT1, (1<<12) @ Unsupported
    .equ UART_RTS, (1<<11) @ Request to send
    .equ UART_DTR, (1<<10) @ Unsupported
    .equ UART_RXE, (1<<9) @ Enable receiver
    .equ UART_TXE, (1<<8) @ Enable transmitter
    .equ UART_LBE, (1<<7) @ Enable loopback
    .equ UART_SIRLP, (1<<2) @ Unsupported
    .equ UART_SIREN, (1<<1) @ Unsupported
    .equ UART_UARTEN, (1<<0) @ Enable UART

  

@@ ----------------------------------------------------------
    .global UART_put_byte
UART_put_byte:
    @ ldr r0,=sendChar
    @ bl printf
    printStr sendChar sendCharLen
    ldr r3,=charTest
    ldr r1,=uartbase @ load base address of UART
    ldr r1,[r1] @ load base address of UART
     
putlp:    
    ldr r2,[r1,#UART_FR] @ read the flag resister
    tst r2,#UART_TXFF @ check if transmit FIFO is full
    bne putlp @ loop while transmit FIFO is full
    str r3,[r1,#UART_DR] @ write the char to the FIFO
@    mov pc,lr @ return

@@@ ---------------------------------------------------------
    .global UART_get_byte
UART_get_byte:
    @ ldr r0,=getChar
    @ bl printf
    printStr getChar
    ldr r1,=uartbase @ load base address of UART
    ldr r1,[r1] @ load base address of UART
getlp:
    ldr r2,[r1,#UART_FR] @ read the flag resister
    tst r2,#UART_RXFE @ check if receive FIFO is empty
    bne getlp @ loop while receive FIFO is empty
    ldr r0,[r1,#UART_DR] @ read the char from the FIFO
    tst r0,#UART_OE @ check for overrun error
    bne get_ok1    
@@ handle receive overrun error here - does nothing now
get_ok1:
    tst r0,#UART_BE @ check for break error
    bne get_ok2
@@ handle receive break error here - does nothing now
get_ok2:
    tst r0,#UART_PE @ check for parity error
    bne get_ok3
@@ handle receive parity error here - does nothing now
get_ok3:
    tst r0,#UART_FE @ check for framing error
    bne get_ok4
@@ handle receive framing error here - does nothing now
get_ok4:
    @@ return
    @bl printf
    bl init_exit
@    mov pc,lr @ return the received character

@@@ ---------------------------------------------------------
    
    @@@ UART init will set default values:
    @@@ 115200 baud, no parity, 2 stop bits, 8 data bits
    .global UART_init
UART_init:  
    @ ldr r0,=inituart
    @ bl printf
    printStr inituart inituartLen
    ldr r1,=uartbase @ load base address of UART
    ldr r1,[r1] @ load base address of UART
    @@mov r0,#0
    @@str r0,[r1,#UART_CR]
    @@ set baud rate divisor
    @@ (3MHz / ( 115200 * 16 )) = 1.62760416667
    @@ = 1.101000 in binary
    mov r0,#1
    str r0,[r1,#UART_IBRD]
    mov r0,#0x28
    str r0,[r1,#UART_FBRD]
    @@ set parity, word length, enable FIFOS
    .equ BITS, (UART_WLEN1|UART_WLEN0|UART_FEN|UART_STP2)
    mov r0,#BITS
    str r0,[r1,#UART_LCRH]
    @@ mask all UART interrupts
    mov r0,#0
    str r0,[r1,#UART_IMSC]
    @@ enable receiver and transmitter and enable the uart
    .equ FINALBITS, (UART_RXE|UART_TXE|UART_UARTEN)
    ldr r0,=FINALBITS
    str r0,[r1,#UART_CR]
    bl UART_put_byte
    @@ return
    mov pc,lr

@ @@ ---------------------------------------------------------
@     @@ UART_set_baud will change the baud rate to whatever is in r0
@     @@ The baud rate divisor is calculated as follows: Baud rate
@     @@ divisor BAUDDIV = (FUARTCLK/(16 Baud rate)) where FUARTCLK
@     @@ is the UART reference clock frequency. The BAUDDIV
@     @@ is comprised of the integer value IBRD and the
@     @@ fractional value FBRD. NOTE: The contents of the
@     @@ IBRD and FBRD registers are not updated until
@     @@ transmission or reception of the current character
@     @@ is complete.
@     .global UART_set_baud
@ UART_set_baud:
@     @@ set baud rate divisor using formula:
@     @@ (3000000.0 / ( R0 * 16 )) ASSUMING 3Mhz clock
@     lsl r1,r0,#4 @ r1 <- desired baud * 16
@     ldr r0,=(3000000<<6)@ Load 3 MHz as a U(26,6) in r0
@     bl divide @ divide clk freq by (baud*16)
@     asr r1,r0,#6 @ put integer divisor into r1
@     and r0,r0,#0x3F @ put fractional divisor into r0
@     ldr r2,=uartbase @ load base address of UART
@     ldr r2,[r2] @ load base address of UART
@     str r1,[r2,#UART_IBRD] @ set integer divisor
@     str r0,[r2,#UART_FBRD] @ set fractional divisor
@     mov pc,lr
