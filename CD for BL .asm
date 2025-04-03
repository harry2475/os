; ������������El Torito��׼��
; �������fasm boot.asm
format binary
org 0x7C00
use16                ; ��ȷָ��16λģʽ

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00   ; ��ջָ��ָ����������ĩβ
    sti

    ; ��ʾ������Ϣ
    mov si, loading_msg
    call print_string

    ; ����DAP�ṹ�����밴FASM�﷨���壩
    mov word [dap_size], 0x0010  ; DAP�ṹ��С=16�ֽ�
    mov word [dap_count], 1       ; ��ȡ1������
    mov word [dap_offset], 0x0000 ; ������ƫ��
    mov word [dap_segment], 0x1000; �ε�ַ0x1000
    mov dword [dap_lba], 1        ; LBA��ʼ�����ţ���32λ��
    mov dword [dap_lba+4], 0      ; ��32λ��������Ϊ0��

    ; ʹ����չ�����ܣ�LBA��
    mov ah, 0x42
    mov dl, 0x80      ; �������ţ���ʱ�̶�Ϊ0x80��
    mov si, dap_size   ; SIָ��DAP�ṹ
    int 0x13
    jc error          ; ʧ����ת

    ; ��ת�����ص��ں�
    jmp 0x1000:0000

; --------------------------
; ������
; --------------------------
error:
    mov si, error_msg
    call print_string
    mov al, ah        ; ��������AH��
    call print_hex
    hlt               ; ͣ���������ѭ����

; --------------------------
; ��ӡ�ַ�������
; ���룺SI=�ַ�����ַ
; --------------------------
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; --------------------------
; ��ӡʮ����������AL��
; --------------------------
print_hex:
    pusha
    mov cx, 2         ; ����2���ַ�
.next:
    rol al, 4         ; ѭ������4λ
    mov bl, al
    and bl, 0x0F
    add bl, '0'
    cmp bl, '9'
    jbe .print
    add bl, 7         ; ����A-F
.print:
    mov ah, 0x0E
    mov al, bl
    int 0x10
    loop .next
    popa
    ret

; --------------------------
; ��������������ڴ����
; --------------------------
loading_msg db "Loading OS...", 0xD, 0xA, 0
error_msg   db "Error: 0x", 0

; --------------------------
; DAP�ṹ����FASM�﷨���壩
; --------------------------
dap_size     dw 0
dap_count    dw 0
dap_offset   dw 0
dap_segment  dw 0
dap_lba      dq 0

; --------------------------
; �����������ĩβ���
; --------------------------
times 510-($-$$) db 0
dw 0xAA55