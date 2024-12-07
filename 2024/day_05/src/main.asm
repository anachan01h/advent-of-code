extern fopen, fclose, getline, free, printf
extern atoi, qsort
extern puts, putchar

section .data
    input db "./input/input", 0
    mode db "r", 0
    solution1 db "Solution 1: %ld", 0x0A, 0
    solution2 db "Solution 2: %ld", 0x0A, 0
    format db "%u", 0x0A, 0
    format2 db "%u %u", 0x0A, 0
    format3 db "%u %u %u", 0x0A, 0

section .bss
    buffer_ptr resq 1
    buffer_size resq 1
    graph resb 100 * 100
    list resb 50

section .text
global main

main:
    ; # Stack frame
    ; [rbp - 8]: &FILE
    ; [rbp - 12]: u32
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rdi, input
    mov rsi, mode
    call fopen                  ; open input file
    mov [rbp - 8], rax          ; save file stream

.next_pair:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; get next line with a pair

    cmp rax, 1
    jle .no_pairs               ; end loop if there is no pair left

    mov rdi, [buffer_ptr]
    call atoi                   ; convert first number

    mov [rbp - 12], eax         ; save first number

    mov rdi, [buffer_ptr]
    add rdi, 3
    call atoi                   ; convert second number

    mov rdi, graph
    mov esi, [rbp - 12]
    mov edx, eax
    call add_edge               ; add edge to graph

    jmp .next_pair

.no_pairs:
    xor r12d, r12d              ; initialize first sum
    xor r13d, r13d              ; initialize second sum

.next_list:
    mov rdi, buffer_ptr
    mov rsi, buffer_size
    mov rdx, [rbp - 8]
    call getline                ; get next line with a list

    cmp rax, -1
    je .no_lines                ; end loop if there is no line left

    mov rdi, list
    mov rsi, [buffer_ptr]
    call string2array           ; convert line into array of numbers
    mov [rbp - 12], eax         ; save array size

    mov rdi, graph
    mov rsi, list
    mov edx, eax
    call is_ordered             ; check if array is ordered

    test al, al
    jz .unordered

    xor ecx, ecx
    mov eax, [rbp - 12]
    shr eax, 1                  ; size / 2 (integer division)
    mov cl, [list + eax]        ; get middle number
    add r12d, ecx               ; add to first sum
    jmp .next_list

.unordered:
    mov rdi, list
    mov esi, [rbp - 12]
    mov edx, 1
    mov rcx, compar
    call qsort                  ; sort the unordered array

    xor ecx, ecx
    mov eax, [rbp - 12]
    shr eax, 1                  ; size / 2 (integer division)
    mov cl, [list + eax]        ; get middle number
    add r13d, ecx               ; add to second sum

    jmp .next_list

.no_lines:
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

; add_edge(graph: &u8, i: u8, j: u8)
add_edge:
    mov ecx, edx
    mov eax, 100
    mul esi
    add eax, ecx
    mov [rdi + rax], byte 1

    ret

; string2array(dest: &u8, src: &char) -> u32
string2array:
    ; # Stack frame
    ; [rbp - 1]: bool
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp - 1], byte 0

    xor edx, edx
    xor ecx, ecx
.loop:
    inc ecx
    cmp [rsi + rcx], byte 0x0A
    sete [rbp - 1]
    je .next
    cmp [rsi + rcx], byte ','
    jne .loop

.next:
    mov [rsi + rcx], byte 0
    push rdi
    push rsi
    push rdx
    push rcx
    mov rdi, rsi
    call atoi
    pop rcx
    pop rdx
    pop rsi
    pop rdi

    mov [rdi + rdx], al
    inc edx
    inc ecx
    lea rsi, [rsi + rcx]
    xor ecx, ecx
    cmp [rbp - 1], byte 0
    je .loop

    mov eax, edx
    leave
    ret

; is_ordered(graph: &u8, list: &u8, size: u32) -> bool
is_ordered:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov r10d, edx

    xor r8d, r8d
.loop1:
    xor ecx, ecx
    mov cl, [rsi + r8]
    mov [rbp - 12], ecx
    mov eax, 100
    mul ecx
    mov [rbp - 4], eax
    
    mov r9d, r8d
    inc r9d
.loop2:
    mov eax, [rbp - 4]
    mov cl, [rsi + r9]
    add eax, ecx
    mov al, [rdi + rax]


    test al, al
    setnz [rbp - 5]
    jz .end

    inc r9d
    cmp r9d, r10d
    jb .loop2

    inc r8d
    mov ecx, r10d
    dec ecx
    cmp r8d, ecx
    jb .loop1

.end:
    xor eax, eax
    mov al, [rbp - 5]
    leave
    ret

; compar(n1: &u8, n2: &u8) -> u32
compar:
    push rbp
    mov rbp, rsp

    xor r8d, r8d
    xor r9d, r9d
    mov r8b, [rdi]
    mov r9b, [rsi]
    xor ecx, ecx

    mov eax, 100
    mul r8d
    mov al, [graph + rax + r9]
    test al, al
    jnz .less

    mov eax, 100
    mul r9d
    mov al, [graph + rax + r8]
    test al, al
    jnz .above

.less:
    dec ecx
    jmp .end

.above:
    inc ecx

.end:
    mov eax, ecx
    leave
    ret
