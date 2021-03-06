@@@ Raspberry Pi devices
@@@ -----------------------------------------------------------
@@@ This file provides a function "IO_init" that will
@@@ map some devices into the user program’s memory
@@@ space. Pointers to the devices are stored in
@@@ global variables, and the user program can then
@@@ use those pointers to access the device registers.
@@@ -----------------------------------------------------------

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
@@ ----------------------------------------------------------        
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

.include "macros.s"
.text
@@@ -----------------------------------------------------------
@@@ The following global variables will hold the addresses of
@@@ the devices that can be accessed directly after IO_init
@@@ has been called.
    .global gpiobase
    gpiobase: .word 0
    .global uartbase
    uartbase: .word 0
    
@@@ -----------------------------------------------------------
@@@ _start abre o arquivo /dev/mem e chama a label que inicia o
@@@ mapeamento da UART
@@@ -----------------------------------------------------------
    .global _start
    _start:        
        stmfd sp!,{r4,r5,lr}
        @@ Try to open /dev/mem
        ldr r6, =memdev @ load address of "/dev/mem"
        ldr r1,=(O_RDWR + O_SYNC) @ set up flags
        openFile memdev, S_RDWR_file @ call the open syscall
        cmp r0,#0 @ check result
        bge init_opened @ if open failed,
        ldr r0, [r0]
        mov r0,#0
        b init_exit
	
@@@ -----------------------------------------------------------
@@@ init_opened chama a label que irá fazer o mapeamento e verifica
@@@ se o mapeamento foi feito com sucesso, além de salvar o mapeamento
@@@ na variavel addr_uart
@@@ -----------------------------------------------------------

init_opened:
    @@ Open succeeded. Now map the devices
    printStr successstr, successstrLen    
    @@ Map the UART device
    bl trymapuart
    cmp r0,#MAP_FAILED
    ldrne r1,=addr_uart @ if succeeded, load pointer
    strne r0,[r1] @ if succeeded, store value

    ldreq r1,=uart0str @ if failed, load pointer to string
    beq map_failed_exit @ if failed, print message

    mov r2,r1    
    @@ All mmaps have succeeded.
    @@ Close file and return 1 for success
    mov r5,#1
    b init_close
    
@@@ -----------------------------------------------------------
@@@ map_failed_exit só acontecerá se o mapeamento falhar, colocando
@@@ o valor de R0 ( R0 é onde o valor retornado do mapemaneto ) para 0
@@@ -----------------------------------------------------------

map_failed_exit:
    @@ At least one mmap failed. Print error,
    @@ unmap everything and return
    printStr mapfailedmsg, mapfailedmsgLen
    ldr r0, [r0, #0]
    bl IO_close
    mov r0,#0
    
@@@ -----------------------------------------------------------
@@@ init_close fecha o arquivo /dev/mem e chama a label UART_init
@@@ -----------------------------------------------------------

init_close:
    mov r0,r4 @ close /dev/mem
    flushClose r0
    b UART_init     
    
@@@ -----------------------------------------------------------
@@@ init_exit fecha o programa
@@@ -----------------------------------------------------------

init_exit:
    mov r0, #0
    mov r7, #1
    svc 0
    
@@@ -----------------------------------------------------------
@@@ trymapuart faz o mapeamento da UART
@@@ -----------------------------------------------------------    

trymapuart: 
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
    ldr r5,=uartadrr @ address of device in memory
    mov r7, #sys_mmap2 @ mmap2 service num
    svc 0 @ call service
    add sp,sp,#8 @ pop params from stack
    cmp r0,#-1
    addne r0,r0,r6 @ add offset from page boundary
    ldmfd sp!,{r5-r7,pc}
    
 @@@ -----------------------------------------------------------
 @@@ IO_close desmapeia todos os dispositivos
 @@@ -----------------------------------------------------------

    .global IO_close
IO_close:
    stmfd sp!,{r4,r5,lr}
    ldr r4,=uartadrr @ get address of first pointer
    mov r5,#4 @ there are 4 pointers

IO_closeloop:
    ldr r0,[r4] @ load address of device
    mov r1,#BLOCK_SIZE
    cmp r0,#0
    mov r7, #sys_munmap
    svc 0
    @blgt munmap @ unmap it
    mov r0,#0
    str r0,[r4],#4 @ store and increment
    subs r5,r5,#1
    bgt IO_closeloop
    ldmfd sp!,{r4,r5,pc}

@@@ -----------------------------------------------------------
@@@ UART_put_byte envia os dados para o registrador de dado (#UART_DR)
@@@ -----------------------------------------------------------

    .global UART_put_byte
UART_put_byte:	
    ldr r3,=charTest
    ldr r3, [r3]
    ldr r1,=addr_uart @ load base address of UART
    ldr r1,[r1] @ load base address of UART         
putlp:    
    ldr r2,[r1,#UART_FR] @ read the flag resister
    tst r2,#UART_TXFF @ check if transmit FIFO is full
    bne putlp @ loop while transmit FIFO is full
    str r3,[r1,#UART_DR] @ write the char to the FIFO
@    mov pc,lr @ return

@@@ -----------------------------------------------------------
@@@ UART_get_byte pega os dados do registrador de dado (#UART_DR)
@@@ e faz a verificação de erros 
@@@ -----------------------------------------------------------
    .global UART_get_byte
UART_get_byte:
	  
    @ ldr r0,=getChar
    @ bl printf
    @printStr getChar, getCharLen
    ldr r1,=addr_uart @ load base address of UART
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
    mov pc,lr @ return the received character

@@@ -----------------------------------------------------------
@@@ UART_init inicializa a UART com as seguintes configurações:
@@@ 115200 baud, no parity, 2 stop bits, 8 data bits
@@@ -----------------------------------------------------------
    .global UART_init
UART_init:  
    printStr inituart, inituartLen    
    ldr r1,=addr_uart @ load base address of UART
    ldr r1,[r1] @ load base address of UART
    mov r0,#0
    str r0,[r1,#UART_CR]
    @@ set baud rate divisor
    @@ (3MHz / ( 115200 * 16 )) = 1.62760416667
    @@ = 1.101000 in binary
    mov r0,#1
    str r0,[r1,#UART_IBRD]
    mov r0,#0x28
    str r0,[r1,#UART_FBRD]
    @ mov r0,#5
    @ str r0,[r1,#UART_IBRD]
    @ mov r0,#0x21
    @ str r0,[r1,#UART_FBRD]
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
    b init_exit

    .align 2
    .data
memdev: .asciz "/dev/mem"
gpioadrr: .word GPIO_BASE
uartadrr: .word UART0_BASE
addr_uart:
	.word 0
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
