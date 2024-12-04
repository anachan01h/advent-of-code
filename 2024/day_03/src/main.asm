extern fopen, fclose, getline, free, atoi, printf
extern regcomp, regexec, regfree

section .data
    input db "./input", 0
    mode db "r", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0
    regex_pattern db "mul(\([0-9]\+\),\([0-9]\+\))\|do()\|don't()", 0

section .bss
    buffer_ptr resq 1
    buffer_size resq 1
    pmatch resb 3 * 8           ; 3 * size of regmatch_t
    error resb 1000
    regex resb 64               ; size of regex_t

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 8]: &FILE
    ; [rbp - 10]: u16
    ; [rbp - 12]: u16
    ; [rpb - 13]: bool
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rdi, input
    mov rsi, mode
    call fopen                  ; open input file
    mov [rbp - 8], rax          ; save file stream

    mov rdi, regex
    mov rsi, regex_pattern
    xor rdx, rdx
    call regcomp                ; compile regex

    mov [rbp - 13], byte 1      ; activate second sum
    xor r12d, r12d              ; initialize first sum
    xor r13d, r13d              ; initialize second sum
.next_line:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; read a line

    cmp rax, -1
    je .end                     ; end loop if there is no line left

    xor ebx, ebx
.next_match:
    mov rdi, regex
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
    mov eax, [pmatch]
    add rdi, rax
    cmp [rdi + 2], byte '('     ; matched a do?
    jne .check_dont

    mov [rbp - 13], byte 1      ; then activate second sum
    jmp .no_sum

.check_dont:
    cmp [rdi + 2], byte 'n'     ; matched a don't?
    jne .sum

    mov [rbp - 13], byte 0      ; then deactivate second sum
    jmp .no_sum

.sum:
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

    mov dl, [rbp - 13]
    test dl, dl                 ; if active...
    jz .no_sum
    add r13d, eax               ; ... then add!

.no_sum:
    add ebx, [pmatch + 4]
    jmp .next_match

.no_match:
    jmp .next_line

.end:
    mov rdi, regex
    call regfree                ; free regex

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
