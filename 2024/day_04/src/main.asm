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
    end resb 1
    string resb 141

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 8]: &FILE
    ; [rbp - 12]: u32
    ; [rbp - 16]: u32
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rdi, input
    mov rsi, mode
    call fopen                  ; open input file
    mov [rbp - 8], rax          ; save file stream

    xor ebx, ebx
.next_line:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; get next line

    cmp rax, -1
    je .no_lines                ; end loop if there is no line left

    mov eax, 140
    mul ebx
    lea rdi, [matrix + eax]
    mov rsi, [buffer_ptr]
    mov edx, 140
    call strncpy                ; copy line to matrix

    inc ebx
    jmp .next_line

.no_lines:

    xor r12d, r12d              ; initialize first counter
    xor r13d, r13d              ; initialize second counter
    xor ebx, ebx
.horizontal:
    mov eax, 140
    mul ebx
    lea rdi, [matrix + eax]
    mov esi, 140
    call count_xmas             ; count xmas horizontally
    add r12d, eax               ; add to counter

    inc ebx
    cmp ebx, 140
    jb .horizontal

    xor ebx, ebx                ; initialize column
.vertical:
    xor ecx, ecx                ; initialize line
.vertical_string:
    mov eax, 140
    mul ecx
    mov al, [matrix + eax + ebx]
    mov [string + ecx], al      ; copy vertical line to string

    inc ecx
    cmp ecx, 140
    jb .vertical_string

    mov rdi, string
    mov esi, 140
    call count_xmas             ; count xmas vertically
    add r12d, eax               ; add to counter

    inc ebx
    cmp ebx, 140
    jb .vertical

    mov ebx, -139               ; initialize diagonal counter
.diagonal1:
    mov rdi, string
    mov esi, 140
    call strclr                 ; clear string

    xor edi, edi                ; initial line
    xor esi, esi                ; initial column
    xor ecx, ecx

    cmp ebx, 0
    jl .init_column1
    add edi, ebx                ; if ebx is non-negative, it's the start line
    jmp .diagonal1_string
.init_column1:
    sub esi, ebx                ; if ebx is negative, the initial column is 0 - ebx

.diagonal1_string:
    mov eax, 140
    mul edi
    mov al, [matrix + eax + esi]
    mov [string + ecx], al      ; copy diagonal line to string

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
    call count_xmas             ; count xmas diagonally (up left to down right)
    add r12d, eax               ; add to counter

    inc ebx
    cmp ebx, 140
    jl .diagonal1

    mov ebx, -139               ; initialize diagonal counter
.diagonal2:
    mov rdi, string
    mov esi, 140
    call strclr                 ; clear string

    xor edi, edi                ; initial line
    mov esi, 139                ; initial column
    xor ecx, ecx

    cmp ebx, 0
    jl .init_column2
    add edi, ebx                ; if ebx is non-negative, it's the initial line
    jmp .diagonal2_string
.init_column2:
    add esi, ebx                ; if ebx is negative, the initial column is 139 + ebx

.diagonal2_string:
    mov eax, 140
    mul edi
    mov al, [matrix + eax + esi]
    mov [string + ecx], al      ; copy diagonal line to string

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
    call count_xmas             ; count xmas diagonally (up right to down left)
    add r12d, eax               ; add to counter

    inc ebx
    cmp ebx, 140
    jl .diagonal2

    mov [rbp - 12], dword 1     ; initial line (ignore first and last)
.loop_x:
    mov [rbp - 16], dword 1     ; initial column (ignore first and last)
.loop_y:
    mov eax, 140
    mul dword [rbp - 12]
    mov ecx, [rbp - 16]
    lea rdi, [matrix + eax + ecx]
    cmp [rdi], byte 'A'         ; if 'A' was found...
    jne .next
    call is_x_mas               ; ... then check for x-mas...
    add r13d, eax               ; ... and add to counter!

.next:
    inc dword [rbp - 16]
    cmp [rbp - 16], dword 139
    jb .loop_y

    inc dword [rbp - 12]
    cmp [rbp - 12], dword 139
    jb .loop_x

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

    xor eax, eax                ; initialize xmas counter
    xor edx, edx                ; initialize block
    xor ecx, ecx                ; initialize position
.loop:
    shr edx, 8                  ; remove one letter
    mov r8b, [rdi + rcx]
    shl r8d, 24
    or edx, r8d                 ; add next letter

    cmp edx, [rbp - 4]          ; compare with "XMAS"
    je .count
    cmp edx, [rbp - 8]          ; compare with "SAMX"
    je .count
    jmp .no_count

.count:
    inc eax                     ; increment xmas counter

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

; is_x_mas(pos: &char) -> bool
is_x_mas:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp - 4], dword "MAS"
    mov [rbp - 8], dword "SAM"
    xor eax, eax

    mov edx, "A"
    shl edx, 8
    mov ecx, edx                ; initialize edx and ecx with "\0A\0"

    xor esi, esi
    mov sil, [rdi - 141]
    or edx, esi                 ; add up left char
    mov sil, [rdi + 141]
    shl esi, 16
    or edx, esi                 ; add down right char

    cmp edx, [rbp - 4]          ; verify patterns
    je .next1
    cmp edx, [rbp - 8]
    jne .end
.next1:
    mov al, 1                   ; found one diagonal

    xor esi, esi
    mov sil, [rdi - 139]
    or ecx, esi                 ; add up right char
    mov sil, [rdi + 139]
    shl esi, 16
    or ecx, esi                 ; add down left char

    cmp ecx, [rbp - 4]          ; verify patterns
    je .next2
    cmp ecx, [rbp - 8]
    jne .end
.next2:
    mov ah, 1                   ; found other diagonal

.end:
    and al, ah
    xor ah, ah
    leave
    ret
