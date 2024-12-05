extern fopen, fclose, getline, free, printf
extern strncpy

section .data
    input db "./input/input", 0
    mode db "r", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0

section .bss
    buffer_ptr resq 1
    buffer_size resq 1
    matrix resb 140 * 140
    string resb 141

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 8]: &FILE
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rdi, input
    mov rsi, mode
    call fopen
    mov [rbp - 8], rax

    xor ebx, ebx
.next_line:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline

    cmp rax, -1
    je .no_lines

    mov eax, 140
    mul ebx
    lea rdi, [matrix + eax]
    mov rsi, [buffer_ptr]
    mov edx, 140
    call strncpy

    inc ebx
    jmp .next_line

.no_lines:

    xor r12d, r12d
    xor r13d, r13d
    xor ebx, ebx
.horizontal:
    mov eax, 140
    mul ebx
    lea rdi, [matrix + eax]
    mov esi, 140
    call count_xmas

    add r12d, eax

    inc ebx
    cmp ebx, 140
    jb .horizontal

    xor ebx, ebx                ; column
.vertical:
    xor ecx, ecx                ; line
.vertical_string:
    mov eax, 140
    mul ecx
    mov al, [matrix + eax + ebx]
    mov [string + ecx], al

    inc ecx
    cmp ecx, 140
    jb .vertical_string

    mov rdi, string
    mov esi, 140
    call count_xmas
    add r12d, eax

    inc ebx
    cmp ebx, 140
    jb .vertical

    mov ebx, -139
.diagonal1:
    mov rdi, string
    mov esi, 140
    call strclr
    xor edi, edi                ; initial line
    xor esi, esi                ; initial column
    xor ecx, ecx

    cmp ebx, 0
    jl .init_column1
    add edi, ebx
    jmp .diagonal1_string
.init_column1:
    sub esi, ebx

.diagonal1_string:
    mov eax, 140
    mul edi
    mov al, [matrix + eax + esi]
    mov [string + ecx], al

    inc edi
    inc esi
    inc ecx
    cmp edi, 140
    jae .diagonal1_next
    cmp esi, 140
    jb .diagonal1_string

.diagonal1_next:
    mov rdi, string
    mov esi, 140
    call count_xmas
    add r12d, eax

    inc ebx
    cmp ebx, 140
    jl .diagonal1

    mov ebx, -139
.diagonal2:
    mov rdi, string
    mov esi, 140
    call strclr
    xor edi, edi                ; initial line
    mov esi, 139                ; initial column
    xor ecx, ecx

    cmp ebx, 0
    jl .init_column2
    add edi, ebx
    jmp .diagonal2_string
.init_column2:
    add esi, ebx

.diagonal2_string:
    mov eax, 140
    mul edi
    mov al, [matrix + eax + esi]
    mov [string + ecx], al

    inc edi
    dec esi
    inc ecx
    cmp edi, 140
    jae .diagonal2_next
    cmp esi, 0
    jge .diagonal2_string

.diagonal2_next:
    mov rdi, string
    mov esi, 140
    call count_xmas
    add r12d, eax

    inc ebx
    cmp ebx, 140
    jl .diagonal2

.end:
    mov rdi, [buffer_ptr]
    call free                   ; free memory from getline

    mov rdi, [rbp - 8]
    call fclose                 ; close file

    mov rdi, solution1
    mov esi, r12d
    xor eax, eax
    call printf                 ; print solution 1

    mov rdi, solution2
    mov esi, r13d
    xor eax, eax
    call printf                 ; print solution 2

    xor eax, eax
    leave
    ret

; count_xmas(text: &char, size: u32) -> u32
count_xmas:
    ; # Stack frame
    ; [rbp - 4]: u32
    ; [rbp - 4]: u32
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov [rbp - 4], dword "XMAS"
    mov [rbp - 8], dword "SAMX"

    xor eax, eax
    xor edx, edx
    xor ecx, ecx
.loop:
    shr edx, 8
    mov r8b, [rdi + rcx]
    shl r8d, 24
    or edx, r8d

    cmp edx, [rbp - 4]
    je .count
    cmp edx, [rbp - 8]
    je .count
    jmp .no_count

.count:
    inc eax

.no_count:
    inc ecx
    cmp ecx, esi
    jb .loop

    leave
    ret

; strclr(string: &char, size: u32)
strclr:
    xor ecx, ecx
.loop:
    mov [rdi + rcx], byte 0
    inc ecx
    cmp ecx, esi
    jb .loop

    ret
