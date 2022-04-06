.equ sys_read, 3 @ read from a file descriptor
.equ sys_write, 4 @ write to a file descriptor
.equ sys_open, 5 @ open and possibly create a file
.equ sys_close, 6 @ close a file descriptor
.equ sys_mount, 21 @ mount filesystem
.equ sys_munmap, 91 @unmap files or devices into memory
.equ sys_fsync, 118 @ synch a file's in-core state with storage
.equ sys_mmap2, 192 @ map files or devices into memory
.equ sys_nanosleep, 162 @ high-resolution sleep
