as -g -o uart_setup.o uart_setup.s
ld -o uart_setup uart_setup.o
sudo gdb ./uart_setup
