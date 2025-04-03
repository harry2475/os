org 0x7C00
use 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00        ; ����ʹ��SP�Ĵ���
    sti

    ; ��ʾ������Ϣ
    mov si, msg
    call print_string

    ; ���̲�����ʼ��
    mov byte [current_track], 0
    mov byte [current_head], 0
    mov byte [current_sector], 1     ; ������1��ʼ
    mov word [current_buffer], 0x8000
    mov byte [sectors_left], 64      ; ����64��������32KB��

read_loop:
    call read_disk
    jc error_handler

    ; ���´��̲���
    inc byte [current_sector]
    cmp byte [current_sector], 18    ; ��׼����ÿ�ŵ�18����
    jbe .no_overflow
    mov byte [current_sector], 1
    inc byte [current_head]
    cmp byte [current_head], 2       ; ˫���ͷ
    jb .no_overflow
    mov byte [current_head], 0
    inc byte [current_track]

.no_overflow:
    add word [current_buffer], 512   ; ��������ַ+512
    dec byte [sectors_left]
    jnz read_loop

    jmp 0x1000:0000                  ; ��ת���ں�

error_handler:
    mov si, error_msg
    call print_string
    mov al, ah                      ; ��������AH��
    call print_hex

    mov byte [retry_count], 3
.retry_loop:
    dec byte [retry_count]
    jz .fatal_error
    mov ah, 0x00                   ; ���̸�λ
    int 0x13                       ; ����ʹ��int 13h
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
    mov bx, 0x0007                 ; ������ʾ����
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
    mov al, 1                       ; ��ȡ1������
    mov ch, [current_track]
    mov cl, [current_sector]        ; �����Ŵ�1��ʼ
    mov dh, [current_head]
    mov dl, 0x80                    ; ��һӲ��
    mov bx, [current_buffer]
    int 0x13
    popa
    ret

; ��������������ڴ���֮��
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