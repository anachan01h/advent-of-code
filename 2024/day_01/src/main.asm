extern atoi, qsort, printf

section .data
    input db "./input", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0
    format db "%u", 0x0A, 0
    format2 db "%u %u", 0x0A, 0

section .bss
    list1 resd 1000
    list2 resd 1000
    buffer resb 14

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 4]: u32
    ; [rbp - 8]: u32
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rax, 0x02
    mov rdi, input
    mov rsi, 0
    syscall                     ; open input file

    cmp eax, 0
    jl .exit                    ; Avisar que deu erro?
    mov [rbp - 4], eax          ; save file descriptor

    xor ecx, ecx
.loop1:
    mov [rbp - 8], ecx          ; save counter
    xor eax, eax
    mov edi, [rbp - 4]
    mov rsi, buffer
    mov rdx, 14
    syscall                     ; read one line

    mov [buffer + 5], byte 0
    mov [buffer + 13], byte 0   ; create zero ended strings

    mov rdi, buffer
    call atoi
    mov ecx, [rbp - 8]
    mov [list1 + 4 * rcx], eax  ; save left number on list1

    mov rdi, buffer + 6
    call atoi
    mov ecx, [rbp - 8]
    mov [list2 + 4 * rcx], eax  ; save right number on list2

    mov ecx, [rbp - 8]
    inc ecx
    cmp ecx, 1000
    jb .loop1

    mov rax, 0x03
    mov edi, [rbp - 4]
    syscall                     ; close input file
    ; Avisar que deu erro?

    mov rdi, list1
    mov rsi, 1000
    mov rdx, 4
    mov rcx, compar
    call qsort                  ; sort list1

    mov rdi, list2
    mov rsi, 1000
    mov rdx, 4
    mov rcx, compar
    call qsort                  ; sort list2

    call problem1
    mov rdi, solution1
    mov rsi, rax
    xor eax, eax
    call printf                 ; print solution for problem 1

    call problem2
    mov rdi, solution2
    mov rsi, rax
    xor eax, eax
    call printf                 ; print solution for problem 2

    xor eax, eax
.exit:
    leave
    ret

; compar(a: &u32, b: &u32) -> i32
compar:
    push rbp
    mov rbp, rsp
    mov edi, [rdi]              ; edi <- *a
    mov esi, [rsi]              ; esi <- *b

    xor eax, eax
    cmp rdi, rsi
    jb .less
    ja .above
    jmp .exit                   ; if (a == b), return 0

.less:
    dec eax                     ; if (a < b), return -1
    jmp .exit

.above:
    inc eax                     ; if (a > b), return 1

.exit:
    leave
    ret

; problem1() -> u64
problem1:
    xor eax, eax
    xor ecx, ecx
.loop1:
    mov edi, [list1 + 4 * rcx]
    mov esi, [list2 + 4 * rcx]
    sub edi, esi                ; edi <- list1[ecx] - list2[ecx]
    mov edx, edi
    neg edi
    cmovl edi, edx              ; edi <- |list1[ecx] - list2[ecx]|
    add rax, rdi

    inc ecx
    cmp ecx, 1000
    jb .loop1

    ret

; problem2() -> u64
problem2:
    xor ecx, ecx
    xor edi, edi                ; edi = i
    xor esi, esi                ; esi = j
.sum:
    mov r8d, [list1 + 4 * edi]  ; r8d <- list1[i]
    mov eax, r8d
    xor edx, edx                ; counter for occurrences of list1[i] in list1
.left_count:
    inc edx
    inc edi
    cmp edi, 1000
    jae .next1

    cmp r8d, [list1 + 4 * edi]
    je .left_count

.next1:
    mul edx

    xor edx, edx                ; counter for occurrences of list1[i] in list2
.right_count:
    cmp r8d, [list2 + 4 * esi]
    jb .next2
    ja .right_count2
    inc edx
.right_count2:
    inc esi
    cmp esi, 1000
    jb .right_count

.next2:
    mul edx
    add rcx, rax

    cmp edi, 1000
    jae .exit
    cmp esi, 1000
    jae .exit                   ; exit if reaches the end of one of the lists
    jmp .sum

.exit:
    mov rax, rcx
    ret
