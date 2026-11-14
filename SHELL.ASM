[BITS 16]
[ORG 0x100]

start:
    call clear_screen
    mov si, banner
    call print_str

main_loop:
    mov si, prompt
    call print_str

    mov di, cmd_buf
    call read_line

    mov si, cmd_buf
    cmp byte [si], 0
    je main_loop

    mov di, cmd_help
    call strcmp
    jc do_help

    mov di, cmd_info
    call strcmp
    jc do_info

    mov di, cmd_cls
    call strcmp
    jc do_cls

    mov di, cmd_exit
    call strcmp
    jc do_exit

    mov si, msg_unknown
    call print_str
    jmp main_loop

do_help:
    mov si, msg_help
    call print_str
    jmp main_loop

do_info:
    mov si, msg_info
    call print_str
    jmp main_loop

do_cls:
    call clear_screen
    jmp main_loop

do_exit:
    mov ax, 0x4C00
    int 0x21

clear_screen:
    mov ax, 0x0600
    mov bh, 0x1F        ; Синий фон, белый текст
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    mov bh, 0
    mov dx, 0x0000
    int 0x10
    ret

print_str:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_str
.done:
    ret

read_line:
    xor cx, cx
.key_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    cmp cx, 30
    jae .key_loop
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .key_loop
.backspace:
    or cx, cx
    jz .key_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .key_loop
.done:
    mov byte [di], 0
    mov si, crlf
    call print_str
    ret

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    or al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    pop di
    pop si
    clc
    ret
.equal:
    pop di
    pop si
    stc
    ret

banner      db '========================================', 13, 10
            db '   MY CUSTOM OS SHELL v1.0 (FreeDOS)    ', 13, 10
            db '========================================', 13, 10
            db 'Type "help" for commands.', 13, 10, 13, 10, 0
prompt      db 'MyOS> ', 0
crlf        db 13, 10, 0

cmd_help    db 'help', 0
cmd_info    db 'info', 0
cmd_cls     db 'cls', 0
cmd_exit    db 'exit', 0

msg_help    db 'Commands: help, info, cls, exit', 13, 10, 0
msg_info    db 'Custom Shell running on FreeDOS in v86!', 13, 10, 0
msg_unknown db 'Unknown command. Type "help".', 13, 10, 0

cmd_buf     times 32 db 0
