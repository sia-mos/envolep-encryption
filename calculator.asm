.model small
.stack 100h

.data
welcome_msg db '===========================',13,10
            db '    ASSEMBLY CALCULATOR    ',13,10
            db '===========================',13,10,'$'

menu_msg db 13,10,'1. Addition (+)'
         db 13,10,'2. Subtraction (-)'
         db 13,10,'3. Multiplication (*)'
         db 13,10,'4. Division (/)'
         db 13,10,'5. Modulus (%)'
         db 13,10,'6. Memory Recall (MR)'
         db 13,10,'7. Memory Clear (MC)'
         db 13,10,'8. Factorial (!)'
         db 13,10,'9. Square (^2)'
         db 13,10,'10. Exit',13,10,'$'

choice_prompt   db 13,10,'Choose operation (1-10): $'
num1_prompt     db 13,10,'Enter first number: $'
num2_prompt     db 13,10,'Enter second number: $'
result_msg      db 13,10,'Result: $'
memory_msg      db 13,10,'Memory: $'
continue_prompt db 13,10,13,10,'Continue? (Y/N): $'

error_div_zero db 13,10,'Error: Division by zero.$'
error_overflow db 13,10,'Error: Overflow.$'
error_invalid  db 13,10,'Error: Invalid choice.$'
error_negative db 13,10,'Error: Factorial requires non-negative number.$'
error_too_large db 13,10,'Error: Number too large for factorial.$'

op_symbol db ' $'
equals    db ' = $'
factorial_symbol db '! = $'
square_symbol db '^2 = $'

num1        dw ?
num2        dw ?
result      dw ?
memory      dw 0
choice      db ?
sign_flag   db 0

.code
main proc
    mov ax, @data
    mov ds, ax

main_loop:
    mov ah, 00h
    mov al, 03h
    int 10h

    lea dx, welcome_msg
    mov ah, 09h
    int 21h

    lea dx, menu_msg
    mov ah, 09h
    int 21h

get_choice:
    lea dx, choice_prompt
    mov ah, 09h
    int 21h

    mov ah, 01h
    int 21h
    sub al, '0'
    mov bl, al
    
    ; Check if it's a two-digit number (10)
    mov ah, 01h
    int 21h
    cmp al, 13
    je single_digit
    cmp al, 10
    je single_digit
    
    ; Two-digit number
    sub al, '0'     ; Convert second digit to number (AL = second digit)
    mov cl, al      ; Save second digit in CL
    mov al, bl      ; Get first digit (BL = first digit)
    mov ah, 0
    mov bx, 10
    mul bx          ; first_digit * 10 (result in AX)
    mov dl, cl      ; Get second digit from CL
    mov dh, 0
    add ax, dx      ; first_digit * 10 + second_digit
    mov choice, al
    jmp check_choice
    
single_digit:
    mov choice, bl

check_choice:
    mov al, choice
    cmp al, 1
    jl invalid
    cmp al, 10
    jg invalid
    cmp al, 10
    je exit_program

    ; Check if factorial or square (only need one number)
    cmp al, 8
    je do_factorial
    cmp al, 9
    je do_square

    ; Check for memory operations
    cmp al, 6
    jge memory_ops

    ; Regular operations need two numbers
    lea dx, num1_prompt
    mov ah, 09h
    int 21h
    call get_number
    mov num1, ax

    lea dx, num2_prompt
    mov ah, 09h
    int 21h
    call get_number
    mov num2, ax

    mov al, choice
    cmp al, 1
    je do_add
    cmp al, 2
    je do_sub
    cmp al, 3
    je do_mul
    cmp al, 4
    je do_div
    cmp al, 5
    je do_mod

do_add:
    mov op_symbol, '+'
    mov ax, num1
    add ax, num2
    jo overflow
    jmp show_result

do_sub:
    mov op_symbol, '-'
    mov ax, num1
    sub ax, num2
    jo overflow
    jmp show_result

do_mul:
    mov op_symbol, '*'
    mov ax, num1
    imul num2
    cmp dx, 0
    jne overflow
    jmp show_result

do_div:
    mov op_symbol, '/'
    mov ax, num1
    cwd
    mov bx, num2
    cmp bx, 0
    je div_zero
    idiv bx
    jmp show_result

do_mod:
    mov op_symbol, '%'
    mov ax, num1
    cwd
    mov bx, num2
    cmp bx, 0
    je div_zero
    idiv bx
    mov ax, dx
    jmp show_result

do_factorial:
    lea dx, num1_prompt
    mov ah, 09h
    int 21h
    call get_number
    mov num1, ax
    
    ; Check if negative
    cmp ax, 0
    jl fact_negative
    
    ; Check if too large (factorial of 8 = 40320, which fits in 16-bit)
    ; But factorial of 9 = 362880, which doesn't fit
    cmp ax, 8
    jg fact_too_large
    
    call factorial
    mov result, ax
    mov memory, ax      ; Store result in memory for recall
    
    lea dx, result_msg
    mov ah, 09h
    int 21h
    
    mov ax, num1
    call print_number
    
    lea dx, factorial_symbol
    mov ah, 09h
    int 21h
    
    mov ax, result
    call print_number
    jmp continue_check

do_square:
    lea dx, num1_prompt
    mov ah, 09h
    int 21h
    call get_number
    mov num1, ax
    
    ; Square the number
    mov ax, num1
    imul ax          ; Result in DX:AX
    jo overflow      ; Check overflow flag first
    cmp dx, 0        ; For 16-bit result, DX must be 0
    jne overflow
    mov result, ax
    mov memory, ax      ; Store result in memory for recall
    
    lea dx, result_msg
    mov ah, 09h
    int 21h
    
    mov ax, num1
    call print_number
    
    lea dx, square_symbol
    mov ah, 09h
    int 21h
    
    mov ax, result
    call print_number
    jmp continue_check

show_result:
    mov result, ax
    mov memory, ax      ; Store result in memory for recall

    lea dx, result_msg
    mov ah, 09h
    int 21h

    mov ax, num1
    call print_number

    lea dx, op_symbol
    mov ah, 09h
    int 21h

    mov ax, num2
    call print_number

    lea dx, equals
    mov ah, 09h
    int 21h

    mov ax, result
    call print_number
    jmp continue_check

memory_ops:
    cmp choice, 6
    je mem_recall
    cmp choice, 7
    je mem_clear

mem_recall:
    lea dx, memory_msg
    mov ah, 09h
    int 21h
    mov ax, memory
    call print_number
    jmp continue_check

mem_clear:
    mov memory, 0
    jmp continue_check

div_zero:
    lea dx, error_div_zero
    mov ah, 09h
    int 21h
    jmp continue_check

overflow:
    lea dx, error_overflow
    mov ah, 09h
    int 21h
    jmp continue_check

fact_negative:
    lea dx, error_negative
    mov ah, 09h
    int 21h
    jmp continue_check

fact_too_large:
    lea dx, error_too_large
    mov ah, 09h
    int 21h
    jmp continue_check

invalid:
    lea dx, error_invalid
    mov ah, 09h
    int 21h
    jmp get_choice

continue_check:
    lea dx, continue_prompt
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    cmp al, 'Y'
    je main_loop
    cmp al, 'y'
    je main_loop

exit_program:
    mov ah, 4Ch
    int 21h
main endp

; -------- FACTORIAL PROCEDURE --------
factorial proc
    push bx
    push cx
    mov ax, num1
    cmp ax, 0
    je fact_zero
    cmp ax, 1
    je fact_one
    
    mov bx, ax      ; bx = n
    mov ax, 1       ; ax = result (start with 1)
    mov cx, 1       ; cx = counter (start with 1)
    
fact_loop:
    inc cx
    cmp cx, bx
    jg fact_done
    mul cx          ; ax = ax * cx
    jo fact_overflow
    jmp fact_loop

fact_zero:
fact_one:
    mov ax, 1
    jmp fact_done

fact_overflow:
    ; Overflow occurred - this shouldn't happen if pre-check is correct
    ; but handle it gracefully
    mov ax, 0FFFFh  ; Return max value to indicate error
    jmp fact_done

fact_done:
    pop cx
    pop bx
    ret
factorial endp

; -------- SIGNED NUMBER INPUT --------
get_number proc
    push bx
    mov bx, 0
    mov sign_flag, 0

    mov ah, 01h
    int 21h
    cmp al, '-'
    jne digit
    mov sign_flag, 1
    jmp next

digit:
    sub al, '0'
    mov bl, al

next:
    mov ah, 01h
    int 21h
    cmp al, 13
    je done
    cmp al, 10
    je done
    sub al, '0'
    cmp al, 9
    jg done          ; Invalid character, treat as end
    mov ah, 0
    mov cx, ax       ; Save new digit in CX
    mov ax, bx       ; Get accumulated value
    mov bx, 10
    mul bx           ; Multiply accumulated value by 10
    add ax, cx       ; Add new digit
    mov bx, ax       ; Store back in BX
    jmp next

done:
    mov ax, bx
    cmp sign_flag, 1
    jne ret_ok
    neg ax

ret_ok:
    pop bx
    ret
get_number endp

; -------- PRINT SIGNED NUMBER --------
print_number proc
    push ax 
    push bx
    push cx
    push dx
    cmp ax, 0
    jge positive
    mov dl, '-'
    mov ah, 02h
    int 21h
    neg ax

positive:
    mov bx, 10
    mov cx, 0
pn_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne pn_loop

print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

end main

