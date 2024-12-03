extern fopen, getline, atoi, printf

section .data
    input db "./input", 0
    mode db "r", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0

section .bss
    buffer_ptr resq 1
    buffer_size resq 1
    line resb 10
    line2 resb 10

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
    call fopen                  ; open input file
    mov [rbp - 8], rax          ; save file stream

    xor rbx, rbx
    xor r12, r12
    mov ecx, 1000
.loop:
    mov [rbp - 12], ecx         ; save counter

    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; read a line

    mov rdi, [buffer_ptr]
    call string2array           ; convert string to array of u8
    mov [rbp - 16], eax         ; save array size

    mov rdi, line
    mov esi, [rbp - 16]
    call is_safe                ; verify safety for problem 1
    add rbx, rax
    
    mov rdi, line
    mov rsi, line2
    mov edx, [rbp - 16]
    call is_safe2               ; verify safety for problem 2
    add r12, rax

    mov ecx, [rbp - 12]         ; restore counter
    loop .loop

    mov rdi, solution1
    mov rsi, rbx
    xor eax, eax
    call printf                 ; print solution 1

    mov rdi, solution2
    mov rsi, r12
    xor eax, eax
    call printf                 ; print solution 2

    xor eax, eax
.exit:
    leave
    ret

; string2array(str: &char) -> u32
string2array:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp - 1], byte 0

    xor ecx, ecx
    mov rsi, rdi
.loop:
    inc rsi
    cmp [rsi], byte 0x0A
    sete [rbp - 1]
    je .next
    cmp [rsi], byte ' '
    jne .loop

.next:
    mov [rsi], byte 0
    push rsi
    push rcx
    call atoi
    pop rcx
    pop rsi

    mov [line + ecx], eax
    inc ecx
    inc rsi
    mov rdi, rsi
    cmp [rbp - 1], byte 0
    je .loop

    mov eax, ecx
    leave
    ret

; is_safe(array: &u8, size: u32) -> bool
is_safe:
    mov r8, rdi
    mov edx, esi
    dec edx
    xor edi, edi
    xor esi, esi
    mov eax, 0x0101

    xor ecx, ecx
.crescent:
    mov dil, [r8 + rcx]
    mov sil, [r8 + rcx + 1]
    sub sil, dil
    cmp sil, 1
    jl .unsafe1
    cmp sil, 3
    jg .unsafe1

    inc ecx
    cmp ecx, edx
    jb .crescent
    jmp .next1

.unsafe1:
    xor al, al

.next1:
    xor ecx, ecx
.decrescent:
    mov dil, [r8 + rcx]
    mov sil, [r8 + rcx + 1]
    sub dil, sil
    cmp dil, 1
    jl .unsafe2
    cmp dil, 3
    jg .unsafe2

    inc ecx
    cmp ecx, edx
    jb .decrescent
    jmp .next2

.unsafe2:
    xor ah, ah

.next2:
    or al, ah
    xor ah, ah
    ret

; remove_one(array1: &u8, array2: &u8, size: u32, index: u32)
remove_one:
    push rbp
    mov rbp, rsp
    xor r8d, r8d
    xor r9d, r9d
.loop:
    cmp r8d, ecx
    je .next
    mov al, [rdi + r8]
    mov [rsi + r9], al
    inc r9d

.next:
    inc r8d
    cmp r8d, edx
    jb .loop

    leave
    ret

; is_safe2(array1: &u8, array2: &u8, size: u32) -> bool
is_safe2:
    push rbp
    mov rbp, rsp
    xor ecx, ecx
.loop:
    call remove_one

    push rdi
    push rsi
    push rdx
    push rcx
    mov rdi, rsi
    mov esi, edx
    dec esi
    call is_safe
    pop rcx
    pop rdx
    pop rsi
    pop rdi

    test al, al
    jnz .end

    inc ecx
    cmp ecx, edx
    jb .loop

.end:
    leave
    ret
