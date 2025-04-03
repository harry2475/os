org 0x7C00
use 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00        ; 必须使用SP寄存器
    sti

    ; 显示启动信息
    mov si, msg
    call print_string

    ; 磁盘参数初始化
    mov byte [current_track], 0
    mov byte [current_head], 0
    mov byte [current_sector], 1     ; 扇区从1开始
    mov word [current_buffer], 0x8000
    mov byte [sectors_left], 64      ; 加载64个扇区（32KB）

read_loop:
    call read_disk
    jc error_handler

    ; 更新磁盘参数
    inc byte [current_sector]
    cmp byte [current_sector], 18    ; 标准软盘每磁道18扇区
    jbe .no_overflow
    mov byte [current_sector], 1
    inc byte [current_head]
    cmp byte [current_head], 2       ; 双面磁头
    jb .no_overflow
    mov byte [current_head], 0
    inc byte [current_track]

.no_overflow:
    add word [current_buffer], 512   ; 缓冲区地址+512
    dec byte [sectors_left]
    jnz read_loop

    jmp 0x1000:0000                  ; 跳转到内核

error_handler:
    mov si, error_msg
    call print_string
    mov al, ah                      ; 错误码在AH中
    call print_hex

    mov byte [retry_count], 3
.retry_loop:
    dec byte [retry_count]
    jz .fatal_error
    mov ah, 0x00                   ; 磁盘复位
    int 0x13                       ; 必须使用int 13h
    jmp read_loop

.fatal_error:
    mov si, fatal_msg
    call print_string
    jmp $

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007                 ; 设置显示属性
    int 0x10
    jmp print_string
.done:
    ret

print_hex:
    pusha
    mov cx, 2
.next_nibble:
    rol al, 4
    mov bl, al
    and bl, 0x0F
    add bl, '0'
    cmp bl, '9'
    jbe .print_char
    add bl, 7
.print_char:
    mov ah, 0x0E
    mov al, bl
    int 0x10
    loop .next_nibble
    popa
    ret

read_disk:
    pusha
    mov ah, 0x02
    mov al, 1                       ; 读取1个扇区
    mov ch, [current_track]
    mov cl, [current_sector]        ; 扇区号从1开始
    mov dh, [current_head]
    mov dl, 0x80                    ; 第一硬盘
    mov bx, [current_buffer]
    int 0x13
    popa
    ret

; 数据区（必须放在代码之后）
msg db "YoungOS Loader v2.0",0
error_msg db "Disk Error: 0x",0
fatal_msg db " Fatal! System Halted.",0

current_track db 0
current_head db 0
current_sector db 0
current_buffer dw 0
sectors_left db 0
retry_count db 0

times 510-($-$$) db 0
dw 0xAA55