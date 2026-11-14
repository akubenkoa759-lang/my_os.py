[BITS 16]
[ORG 0x100]

start:
    xor ax, ax
    int 0x33                ; Включаем мышь
    mov byte [dir], 0       ; 0=Корень, 1=Office, 2=Games

loop_ui:
    mov ax, 2
    int 0x33                ; Скрыть курсор мыши при отрисовке
    mov ax, 0x0600
    mov bh, 0x70            ; Белый фон, чёрный текст
    xor cx, cx
    mov dx, 0x184F
    int 0x10

    ; Чёрная шапка окна
    mov ax, 0x0600
    mov bh, 0x0F
    xor cx, cx
    mov dx, 0x004F
    int 0x10

    mov dx, 0x0002
    mov si, s_head
    call p_at

    cmp byte [dir], 1
    je .ui_off
    cmp byte [dir], 2
    je .ui_gam

    ; Главный экран (папки)
    mov dx, 0x0405
    mov si, s_root
    call p_at
    jmp .wait

.ui_off:
    mov dx, 0x0405
    mov si, s_off
    call p_at
    jmp .wait

.ui_gam:
    mov dx, 0x0405
    mov si, s_gam
    call p_at

.wait:
    mov ax, 1
    int 0x33                ; Показать курсор мыши

.poll:
    mov ax, 3
    int 0x33
    test bl, 1              ; Клик левой кнопкой мыши?
    jz .kbd
    shr cx, 3               ; X в символах
    shr dx, 3               ; Y в строках
.rel:
    push cx
    push dx
    mov ax, 3
    int 0x33
    test bl, 1
    pop dx
    pop cx
    jnz .rel

    cmp dx, 0
    jne .not_x
    cmp cx, 75
    jae exit_dos            ; Клик по [X]
.not_x:
    cmp dx, 4
    jne .poll
    cmp cx, 16
    jbe .btn1
    cmp cx, 32
    jbe .btn2
    cmp cx, 46
    jbe .btn3
    jmp .poll

.kbd:
    mov ah, 1
    int 0x16
    jz .poll
    xor ah, ah
    int 0x16
    cmp al, 27
    je .btn3
    cmp al, '1'
    je .btn1
    cmp al, '2'
    je .btn2
    cmp al, '3'
    je .btn3
    jmp .poll

.btn1:
    cmp byte [dir], 0
    je .go_off
    cmp byte [dir], 1
    je app_note
    jmp app_tet
.btn2:
    cmp byte [dir], 0
    je .go_gam
    cmp byte [dir], 1
    je app_calc
    jmp .poll
.btn3:
    cmp byte [dir], 0
    je exit_dos
    mov byte [dir], 0
    jmp loop_ui
.go_off:
    mov byte [dir], 1
    jmp loop_ui
.go_gam:
    mov byte [dir], 2
    jmp loop_ui

exit_dos:
    mov ax, 2
    int 0x33
    mov ax, 3
    int 0x10
    mov ax, 0x4C00
    int 0x21

; --- БЛОКНОТ ---
app_note:
    call cls_app
    mov si, s_np
    call p_str
.l: xor ah, ah
    int 0x16
    cmp al, 27
    je loop_ui
    cmp al, 13
    je .nl
    mov ah, 0x0E
    int 0x10
    jmp .l
.nl:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    jmp .l

; --- КАЛЬКУЛЯТОР ---
app_calc:
    call cls_app
    mov si, s_c1
    call p_str
    call r_num
    mov bx, ax
    mov si, s_c2
    call p_str
    call r_num
    add ax, bx
    push ax
    mov si, s_c3
    call p_str
    pop ax
    call p_num
    xor ah, ah
    int 0x16
    jmp loop_ui

; --- МИНИ-ТЕТРИС ---
app_tet:
    call cls_app
    mov byte [tx], 38
    mov byte [ty], 2
.tl:
    mov dh, [ty]
    mov dl, [tx]
    mov si, s_blk
    call p_at
    mov ah, 0x86
    xor cx, cx
    mov dx, 50000
    int 0x15
    mov dh, [ty]
    mov dl, [tx]
    mov si, s_emp
    call p_at
    mov ah, 1
    int 0x16
    jz .fall
    xor ah, ah
    int 0x16
    cmp al, 27
    je loop_ui
    cmp ah, 0x4B
    jne .kr
    dec byte [tx]
.kr:
    cmp ah, 0x4D
    jne .fall
    inc byte [tx]
.fall:
    inc byte [ty]
    cmp byte [ty], 22
    jb .tl
    mov dh, 22
    mov dl, [tx]
    mov si, s_blk
    call p_at
    mov byte [ty], 2
    mov byte [tx], 38
    jmp .tl

; --- УТИЛИТЫ ---
cls_app:
    mov ax, 2
    int 0x33
    mov ax, 0x0600
    mov bh, 0x70
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov dx, 0x0101
    mov ah, 2
    xor bh, bh
    int 0x10
    ret

p_at:
    mov ah, 2
    xor bh, bh
    int 0x10
p_str:
    lodsb
    or al, al
    jz .d
    mov ah, 0x0E
    int 0x10
    jmp p_str
.d: ret

r_num:
    xor cx, cx
.rl:
    xor ah, ah
    int 0x16
    cmp al, 13
    je .rd
    sub al, '0'
    mov bl, al
    mov ax, cx
    mov dx, 10
    mul dx
    add al, bl
    mov cx, ax
    add bl, '0'
    mov ah, 0x0E
    mov al, bl
    int 0x10
    jmp .rl
.rd:
    mov ax, cx
    ret

p_num:
    xor cx, cx
    mov bx, 10
.pd:
    xor dx, dx
    div bx
    push dx
    inc cx
    or ax, ax
    jnz .pd
.pp:
    pop ax
    add al, '0'
    mov ah, 0x0E
    int 0x10
    loop .pp
    ret

dir     db 0
tx      db 38
ty      db 2
s_head  db 'MyOS B&W Desktop                                                          [X]', 0
s_root  db '[1: Office]    [2: Games]     [3: Exit DOS]', 0
s_off   db '[1: Notepad]   [2: Calc]      [3: < Back]', 0
s_gam   db '[1: Tetris]    [2: ---]       [3: < Back]', 0
s_np    db 'NOTEPAD (ESC=Exit):', 13, 10, 0
s_c1    db 'Num 1: ', 0
s_c2    db 13, 10, 'Num 2: ', 0
s_c3    db 13, 10, 'Sum = ', 0
s_blk   db '[]', 0
s_emp   db '  ', 0
