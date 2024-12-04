extern fopen, fclose, getline, free, atoi, printf
extern regcomp, regexec, regfree

section .data
    input db "./input", 0
    mode db "r", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0
regex_pattern:
    .mul db "mul(\([0-9]\+\),\([0-9]\+\))", 0
    .do db "do()", 0
    .dont db "don't()", 0

section .bss
    buffer_ptr resq 1
    buffer_size resq 1
    pmatch resb 3 * 8           ; 1 * size of regmatch_t
    error resb 1000
regex:
    .mul resb 64                ; size of regex_t
    .do resb 64
    .dont resb 64

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 8]: &FILE
    ; [rbp - 10]: u16
    ; [rbp - 12]: u16
    ; [rpb - 16]: u32
    ; [rbp - 20]: u32
    ; [rbp - 24]: u32
    ; [rbp - 28]: u32
    ; [rbp - 32]: u32
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rdi, input
    mov rsi, mode
    call fopen                  ; open input file
    mov [rbp - 8], rax          ; save file stream

    mov rdi, regex.mul
    mov rsi, regex_pattern.mul
    xor rdx, rdx
    call regcomp

    mov rdi, regex.do
    mov rsi, regex_pattern.do
    xor rdx, rdx
    call regcomp

    mov rdi, regex.dont
    mov rsi, regex_pattern.dont
    xor rdx, rdx
    call regcomp                ; compile regex's

    mov [rbp - 28], dword 0     ; initialize line size
    mov [rbp - 16], dword -1    ; initialize do position
    mov [rbp - 20], dword 1     ; initialize dont position

    xor r12d, r12d
    xor r13d, r13d
.next_line:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; read a line
    mov [rbp - 32], eax

    cmp rax, -1
    je .end                     ; end loop if there is no line left

    mov edx, [rbp - 16]
    sub edx, [rbp - 28]
    cmp edx, 0
    jl .no_calc4do

    mov rdi, regex.do
    mov rsi, [buffer_ptr]
    mov rdx, 1
    mov rcx, pmatch
    xor r8, r8
    call regexec

    mov edx, [pmatch + 4]

.no_calc4do:
    mov [rbp - 16], edx         ; update do position

    mov edx, [rbp - 20]
    sub edx, [rbp - 28]
    cmp edx, 1
    jne .no_calc4dont

    mov rdi, regex.dont
    mov rsi, [buffer_ptr]
    cmp [rbp - 16], dword 0
    jl .no_offset
    mov edx, [rbp - 16]
    add rsi, rdx
.no_offset:
    mov rdx, 1
    mov rcx, pmatch
    xor r8, r8
    call regexec

    mov edx, [pmatch + 4]
    cmp [rbp - 16], dword 0
    jl .no_calc4dont
    add edx, [rbp - 16]
.no_calc4dont:
    mov [rbp - 20], edx         ; update dont position

    mov eax, [rbp - 32]
    mov [rbp - 28], eax
    xor ebx, ebx
.next_match:
    mov rdi, regex.mul
    mov rsi, [buffer_ptr]
    add rsi, rbx
    mov rdx, 3
    mov rcx, pmatch
    xor r8, r8
    call regexec                ; get next match

    test eax, eax
    jnz .no_match

    mov rdi, [buffer_ptr]
    add rdi, rbx
    mov eax, [pmatch + 8]
    add rdi, rax
    call atoi                   ; convert first number
    mov [rbp - 10], ax

    mov rdi, [buffer_ptr]
    add rdi, rbx
    mov eax, [pmatch + 16]
    add rdi, rax
    call atoi                   ; convert second number
    mov [rbp - 12], ax

    xor edx, edx
    mov dx, [rbp - 10]
    mul edx                     ; multiply...
    add r12d, eax               ; ... then add!
    mov [rbp - 24], eax         ; save product

    add ebx, [pmatch + 4]

    cmp ebx, [rbp - 20]
    jl .next

    mov edx, [rbp - 20]
    mov rdi, regex.do
    mov rsi, [buffer_ptr]
    add rsi, rdx
    mov rdx, 1
    mov rcx, pmatch
    xor r8, r8
    call regexec

    test eax, eax
    jz .found_do
    mov eax, [rbp - 28]
    mov [rbp - 16], eax
    jmp .find_dont

.found_do:
    mov eax, [pmatch + 4]
    add eax, [rbp - 20]
    mov [rbp - 16], eax

.find_dont:
    mov edx, [rbp - 16]
    mov rdi, regex.dont
    mov rsi, [buffer_ptr]
    add rsi, rdx
    mov rdx, 1
    mov rcx, pmatch
    xor r8, r8
    call regexec

    test eax, eax
    jz .found_dont
    mov eax, [rbp - 28]
    inc eax
    mov [rbp - 20], eax
    jmp .test

.found_dont:
    mov eax, [pmatch + 4]
    add eax, [rbp - 16]
    mov [rbp - 20], eax

.test:
    cmp ebx, [rbp - 16]
    jg .sum
    jmp .no_sum

.next:
    cmp ebx, [rbp - 16]
    jl .no_sum

.sum:
    add r13d, [rbp - 24]

.no_sum:
    jmp .next_match

.no_match:
    jmp .next_line

.end:
    mov rdi, regex.mul
    call regfree

    mov rdi, regex.do
    call regfree

    mov rdi, regex.dont
    call regfree

    mov rdi, [buffer_ptr]
    call free

    mov rdi, [rbp - 8]
    call fclose

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
