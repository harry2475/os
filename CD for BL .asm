; 光盘引导程序（El Torito标准）
; 编译命令：fasm boot.asm
format binary
org 0x7C00
use16                ; 明确指定16位模式

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00   ; 堆栈指针指向引导程序末尾
    sti

    ; 显示引导信息
    mov si, loading_msg
    call print_string

    ; 设置DAP结构（必须按FASM语法定义）
    mov word [dap_size], 0x0010  ; DAP结构大小=16字节
    mov word [dap_count], 1       ; 读取1个扇区
    mov word [dap_offset], 0x0000 ; 缓冲区偏移
    mov word [dap_segment], 0x1000; 段地址0x1000
    mov dword [dap_lba], 1        ; LBA起始扇区号（低32位）
    mov dword [dap_lba+4], 0      ; 高32位（必须设为0）

    ; 使用扩展读功能（LBA）
    mov ah, 0x42
    mov dl, 0x80      ; 驱动器号（临时固定为0x80）
    mov si, dap_size   ; SI指向DAP结构
    int 0x13
    jc error          ; 失败跳转

    ; 跳转到加载的内核
    jmp 0x1000:0000

; --------------------------
; 错误处理
; --------------------------
error:
    mov si, error_msg
    call print_string
    mov al, ah        ; 错误码在AH中
    call print_hex
    hlt               ; 停机（替代死循环）

; --------------------------
; 打印字符串函数
; 输入：SI=字符串地址
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
; 打印十六进制数（AL）
; --------------------------
print_hex:
    pusha
    mov cx, 2         ; 处理2个字符
.next:
    rol al, 4         ; 循环左移4位
    mov bl, al
    and bl, 0x0F
    add bl, '0'
    cmp bl, '9'
    jbe .print
    add bl, 7         ; 调整A-F
.print:
    mov ah, 0x0E
    mov al, bl
    int 0x10
    loop .next
    popa
    ret

; --------------------------
; 数据区（必须放在代码后）
; --------------------------
loading_msg db "Loading OS...", 0xD, 0xA, 0
error_msg   db "Error: 0x", 0

; --------------------------
; DAP结构（按FASM语法定义）
; --------------------------
dap_size     dw 0
dap_count    dw 0
dap_offset   dw 0
dap_segment  dw 0
dap_lba      dq 0

; --------------------------
; 填充引导扇区末尾标记
; --------------------------
times 510-($-$$) db 0
dw 0xAA55