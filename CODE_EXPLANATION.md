# Assembly Calculator - Detailed Code Explanation for Viva

## 1. DIRECTIVE SECTION (Lines 1-2)

```assembly
.model small
.stack 100h
```

**Explanation:**
- **`.model small`**: Defines the memory model. "Small" means:
  - Code segment ≤ 64KB
  - Data segment ≤ 64KB
  - Stack segment ≤ 64KB
  - Suitable for small programs like this calculator
  
- **`.stack 100h`**: Allocates 256 bytes (100h in hexadecimal) for the stack
  - Stack is used for:
    - Storing return addresses during procedure calls
    - Saving register values (push/pop operations)
    - Temporary storage during calculations

---

## 2. DATA SEGMENT (Lines 4-43)

### 2.1 String Messages (Lines 5-31)

```assembly
welcome_msg db '===========================',13,10
            db '    ASSEMBLY CALCULATOR    ',13,10
            db '===========================',13,10,'$'
```

**Explanation:**
- **`db`**: Define Byte - declares byte-sized data
- **`13,10`**: ASCII codes for Carriage Return (CR) and Line Feed (LF) = newline
- **`'$'`**: String terminator for DOS interrupt 21h function 09h (print string)
- Multiple `db` lines concatenate to form one string

**All String Variables:**
- `welcome_msg`: Header display
- `menu_msg`: Shows all available operations (1-11)
- `choice_prompt`: Asks user to select operation
- `num1_prompt`, `num2_prompt`: Input prompts
- `result_msg`: Displays "Result:"
- `continue_prompt`: Asks if user wants to continue
- Error messages: Handle various error conditions

### 2.2 Operation Symbols (Lines 33-36)

```assembly
op_symbol db ' $'
equals    db ' = $'
factorial_symbol db '! = $'
square_symbol db '^2 = $'
```

**Explanation:**
- Store operation symbols for display
- Used when showing results (e.g., "5 + 3 = 8")

### 2.3 Variables (Lines 38-43)

```assembly
num1        dw ?
num2        dw ?
result      dw ?
memory      dw 0
choice      db ?
sign_flag   db 0
```

**Explanation:**
- **`dw`**: Define Word (16-bit, 2 bytes)
  - `num1`, `num2`: Store input numbers
  - `result`: Stores calculation result
  - `memory`: Memory register (initialized to 0)
  
- **`db`**: Define Byte (8-bit, 1 byte)
  - `choice`: Stores user's menu selection (1-11)
  - `sign_flag`: Flag to track if input number is negative (0=positive, 1=negative)

- **`?`**: Uninitialized variable (value unknown at compile time)

---

## 3. CODE SEGMENT - MAIN PROCEDURE (Lines 45-336)

### 3.1 Initialization (Lines 46-48)

```assembly
main proc
    mov ax, @data
    mov ds, ax
```

**Explanation:**
- **`main proc`**: Start of main procedure
- **`mov ax, @data`**: Load address of data segment into AX
- **`mov ds, ax`**: Set Data Segment (DS) register
  - DS must point to data segment to access variables
  - Cannot directly move immediate value to segment register

### 3.2 Main Loop (Lines 50-61)

```assembly
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
```

**Explanation:**
- **`main_loop:`**: Label marking start of program loop
- **`int 10h` with AH=00h, AL=03h**: BIOS interrupt to clear screen
  - Sets video mode 03h (80x25 text mode)
  - Clears display for fresh start each iteration

- **`lea dx, welcome_msg`**: Load Effective Address
  - Gets offset address of welcome_msg into DX
  - DX must contain offset for string operations

- **`int 21h` with AH=09h**: DOS interrupt to print string
  - Prints string starting at DS:DX until '$' is encountered
  - Used for all string output

### 3.3 Getting User Choice (Lines 63-91)

```assembly
get_choice:
    lea dx, choice_prompt
    mov ah, 09h
    int 21h

    mov ah, 01h
    int 21h
    sub al, '0'
    mov bl, al
    
    ; Check if it's a two-digit number (10 or 11)
    mov ah, 01h
    int 21h
    cmp al, 13
    je single_digit
    cmp al, 10
    je single_digit
    
    ; Two-digit number
    sub al, '0'
    mov ah, 0
    mov cx, 10
    mul cx
    add al, bl
    mov choice, al
    jmp check_choice
    
single_digit:
    mov choice, bl
```

**Explanation:**
- **`int 21h` with AH=01h**: Read single character from keyboard
  - Character returned in AL
  - Echoes character to screen
  - Waits for keypress

- **`sub al, '0'`**: Convert ASCII to numeric value
  - ASCII '0' = 48, '1' = 49, etc.
  - Subtracting '0' converts '1' → 1, '2' → 2, etc.

- **Two-digit handling**:
  - Reads first digit, stores in BL
  - Reads second character
  - If it's Enter (13) or Line Feed (10), it's single digit
  - Otherwise, it's second digit of 10 or 11
  - Formula: `first_digit * 10 + second_digit`
  - Example: '1' and '0' → 1*10 + 0 = 10

### 3.4 Choice Validation (Lines 93-100)

```assembly
check_choice:
    mov al, choice
    cmp al, 1
    jl invalid
    cmp al, 11
    jg invalid
    cmp al, 11
    je exit_program
```

**Explanation:**
- **`cmp al, 1`**: Compare choice with 1
- **`jl invalid`**: Jump if Less (choice < 1)
- **`jg invalid`**: Jump if Greater (choice > 11)
- **`je exit_program`**: Jump if Equal (choice == 11, exit)
- Validates input is between 1-11

### 3.5 Operation Routing (Lines 102-135)

```assembly
    ; Check if factorial or square (only need one number)
    cmp al, 9
    je do_factorial
    cmp al, 10
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
```

**Explanation:**
- **Priority order**:
  1. Check for factorial (9) or square (10) - single input
  2. Check for memory ops (6-8) - no input needed
  3. Regular arithmetic (1-5) - two inputs required

- **`call get_number`**: Calls procedure to read signed number
  - Returns value in AX register
  - Handles negative numbers

### 3.6 Arithmetic Operations

#### Addition (Lines 137-142)
```assembly
do_add:
    mov op_symbol, '+'
    mov ax, num1
    add ax, num2
    jo overflow
    jmp show_result
```

**Explanation:**
- **`add ax, num2`**: Adds num2 to AX (which contains num1)
  - Result stored in AX
  - Sets flags: Zero, Sign, Carry, Overflow

- **`jo overflow`**: Jump if Overflow flag set
  - Overflow occurs when result exceeds 16-bit signed range (-32768 to 32767)
  - Example: 20000 + 20000 = 40000 (overflow)

#### Subtraction (Lines 144-149)
```assembly
do_sub:
    mov op_symbol, '-'
    mov ax, num1
    sub ax, num2
    jo overflow
    jmp show_result
```

**Explanation:**
- **`sub ax, num2`**: Subtracts num2 from num1
- Overflow check same as addition

#### Multiplication (Lines 151-157)
```assembly
do_mul:
    mov op_symbol, '*'
    mov ax, num1
    imul num2
    cmp dx, 0
    jne overflow
    jmp show_result
```

**Explanation:**
- **`imul num2`**: Signed multiplication
  - Multiplies AX by num2
  - Result: DX:AX (32-bit result)
  - DX = high 16 bits, AX = low 16 bits

- **`cmp dx, 0`**: Check if high word is zero
  - If DX ≠ 0, result doesn't fit in 16 bits → overflow
  - Only 16-bit results are supported

#### Division (Lines 159-167)
```assembly
do_div:
    mov op_symbol, '/'
    mov ax, num1
    cwd
    mov bx, num2
    cmp bx, 0
    je div_zero
    idiv bx
    jmp show_result
```

**Explanation:**
- **`cwd`**: Convert Word to Doubleword
  - Extends sign of AX into DX
  - For signed division, dividend must be in DX:AX
  - If AX is positive, DX = 0
  - If AX is negative, DX = FFFFh

- **`idiv bx`**: Signed division
  - Divides DX:AX by BX
  - Quotient in AX, remainder in DX

- **Division by zero check**: Prevents program crash

#### Modulus (Lines 169-177)
```assembly
do_mod:
    mov op_symbol, '%'
    mov ax, num1
    cwd
    mov bx, num2
    cmp bx, 0
    je div_zero
    idiv bx
    mov ax, dx
```

**Explanation:**
- Same as division, but result is remainder (DX) not quotient (AX)
- **`mov ax, dx`**: Move remainder to AX for display

### 3.7 Factorial Operation (Lines 179-211)

```assembly
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
```

**Explanation:**
- **Input validation**:
  - Negative numbers: Factorial undefined for negatives
  - Upper limit: 8! = 40320 (fits in 16-bit)
  - 9! = 362880 (exceeds 16-bit signed max 32767)

- **Why limit to 8?**
  - 16-bit signed integer range: -32768 to 32767
  - 8! = 40320 (within range)
  - 9! = 362880 (overflow)

### 3.8 Square Operation (Lines 213-239)

```assembly
do_square:
    lea dx, num1_prompt
    mov ah, 09h
    int 21h
    call get_number
    mov num1, ax
    
    ; Square the number
    imul ax
    cmp dx, 0
    jne overflow
    mov result, ax
```

**Explanation:**
- **`imul ax`**: Multiply AX by itself (square)
  - Result in DX:AX
  - If DX ≠ 0, result doesn't fit in 16 bits

- **Overflow check**: Same as multiplication
  - Example: 200² = 40000 (fits)
  - 200² = 40000, but 181² = 32761 (close to limit)

### 3.9 Display Result (Lines 241-264)

```assembly
show_result:
    mov result, ax

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
```

**Explanation:**
- Displays: "Result: num1 op_symbol num2 = result"
- Example: "Result: 5 + 3 = 8"
- Uses `print_number` procedure for signed number display

### 3.10 Memory Operations (Lines 266-290)

```assembly
memory_ops:
    cmp choice, 6
    je mem_add
    cmp choice, 7
    je mem_recall
    cmp choice, 8
    je mem_clear

mem_add:
    mov ax, memory
    add ax, result
    mov memory, ax
    jmp continue_check

mem_recall:
    lea dx, result_msg
    mov ah, 09h
    int 21h
    mov ax, memory
    call print_number
    jmp continue_check

mem_clear:
    mov memory, 0
    jmp continue_check
```

**Explanation:**
- **M+ (Memory Add)**: Adds current result to memory
  - `memory = memory + result`
  - Accumulates values

- **MR (Memory Recall)**: Displays memory value
  - Shows current memory contents

- **MC (Memory Clear)**: Resets memory to 0

### 3.11 Error Handlers (Lines 292-314)

```assembly
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
```

**Explanation:**
- Centralized error handling
- Each error type has specific message
- All jump to `continue_check` to ask if user wants to continue

### 3.12 Continue/Exit Logic (Lines 322-335)

```assembly
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
```

**Explanation:**
- Asks user if they want to continue
- Accepts 'Y' or 'y' (case-insensitive)
- If yes, jumps back to `main_loop`
- Otherwise, exits

- **`int 21h` with AH=4Ch**: DOS terminate program
  - Returns control to DOS
  - Standard way to exit program

---

## 4. PROCEDURES

### 4.1 Factorial Procedure (Lines 338-375)

```assembly
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
```

**Explanation:**
- **Algorithm**: Iterative factorial calculation
  - n! = 1 × 2 × 3 × ... × n
  - Start with result = 1
  - Multiply by 2, 3, 4, ..., n

- **Register usage**:
  - BX: Stores n (input value)
  - AX: Accumulates result (starts at 1)
  - CX: Counter (2 to n)

- **`push bx`, `push cx`**: Save registers
  - Procedures should preserve caller's register values
  - Restored with `pop` before return

- **Special cases**:
  - 0! = 1 (mathematical definition)
  - 1! = 1

- **`mul cx`**: Unsigned multiplication
  - Multiplies AX by CX
  - Result in AX (for values ≤ 8, fits in 16 bits)

- **`jo fact_overflow`**: Check overflow flag
  - Shouldn't occur if pre-validation is correct
  - Safety check

### 4.2 Get Number Procedure (Lines 377-417)

```assembly
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
    sub al, '0'
    mov ah, 0
    mov cx, bx
    mov bx, 10
    mul bx
    add ax, cx
    mov bx, ax
    jmp next

done:
    mov ax, bx
    cmp sign_flag, 1
    jne ret_ok
    neg ax

ret_ok:
    pop bx
    ret
```

**Explanation:**
- **Purpose**: Reads signed integer from keyboard
- **Algorithm**: Builds number digit by digit

**Step-by-step:**
1. **Check for negative sign**:
   - Read first character
   - If '-', set `sign_flag = 1`
   - Otherwise, treat as first digit

2. **Read digits**:
   - Convert ASCII to number: `sub al, '0'`
   - For each new digit:
     - Current value × 10 + new digit
     - Example: "123"
       - First: 1
       - Second: 1×10 + 2 = 12
       - Third: 12×10 + 3 = 123

3. **Stop on Enter**:
   - ASCII 13 = Carriage Return (Enter key)
   - When Enter pressed, stop reading

4. **Apply sign**:
   - If `sign_flag = 1`, negate result
   - `neg ax`: Two's complement negation

**Example: Input "-45"**
- Read '-': set sign_flag = 1
- Read '4': bx = 4
- Read '5': bx = 4×10 + 5 = 45
- Read Enter: done
- Apply sign: ax = -45

### 4.3 Print Number Procedure (Lines 419-455)

```assembly
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
```

**Explanation:**
- **Purpose**: Displays signed integer
- **Algorithm**: Extract digits using division, store on stack, print in reverse

**Step-by-step:**
1. **Handle negative**:
   - If number < 0, print '-' sign
   - Negate number to make it positive

2. **Extract digits** (using stack):
   - Divide by 10 repeatedly
   - Remainder = last digit
   - Push remainder on stack
   - Continue until quotient = 0
   - Stack stores digits in reverse order

3. **Print digits**:
   - Pop digits from stack (now in correct order)
   - Convert to ASCII: `add dl, '0'`
   - Print using `int 21h` with AH=02h (print character)

**Example: Print 123**
- 123 ÷ 10 = 12 remainder 3 → push 3
- 12 ÷ 10 = 1 remainder 2 → push 2
- 1 ÷ 10 = 0 remainder 1 → push 1
- Stack: [1, 2, 3] (top to bottom)
- Pop and print: "123"

**Why use stack?**
- Digits extracted in reverse (right to left)
- Stack reverses order automatically (LIFO)
- Print in correct order (left to right)

**Register preservation**:
- Saves all used registers (AX, BX, CX, DX)
- Restores before return
- Procedure should not modify caller's registers

---

## 5. KEY CONCEPTS FOR VIVA

### 5.1 Interrupts Used

1. **INT 10h (BIOS Video)**:
   - AH=00h: Set video mode (clear screen)

2. **INT 21h (DOS Functions)**:
   - AH=01h: Read character with echo
   - AH=02h: Print character
   - AH=09h: Print string
   - AH=4Ch: Terminate program

### 5.2 Data Types

- **Byte (db)**: 8 bits, range 0-255 or -128 to 127
- **Word (dw)**: 16 bits, range 0-65535 or -32768 to 32767

### 5.3 Addressing Modes

- **Immediate**: `mov ax, 5` (value directly in instruction)
- **Direct**: `mov ax, num1` (variable name)
- **Register**: `mov ax, bx` (register to register)
- **Effective Address**: `lea dx, welcome_msg` (load address)

### 5.4 Flags

- **Overflow Flag (OF)**: Set when signed arithmetic result exceeds range
- **Zero Flag (ZF)**: Set when result is zero
- **Sign Flag (SF)**: Set when result is negative
- **Carry Flag (CF)**: Set when unsigned arithmetic overflows

### 5.5 Procedure Calling Convention

1. **Call**: `call procedure_name`
   - Pushes return address on stack
   - Jumps to procedure

2. **Return**: `ret`
   - Pops return address from stack
   - Jumps back to caller

3. **Register Preservation**:
   - Save registers used: `push reg`
   - Restore before return: `pop reg`

### 5.6 Stack Operations

- **Push**: `push ax` - Decrements SP, stores value
- **Pop**: `pop ax` - Loads value, increments SP
- **LIFO**: Last In First Out principle

### 5.7 Signed vs Unsigned Operations

- **Signed**: `add`, `sub`, `imul`, `idiv` (two's complement)
- **Unsigned**: `mul`, `div` (no sign bit)
- **This program uses signed operations** (supports negative numbers)

---

## 6. COMMON VIVA QUESTIONS

**Q: Why use `.model small`?**
A: Suitable for programs with code and data each ≤ 64KB. This calculator fits easily.

**Q: Why is stack size 100h?**
A: 256 bytes is sufficient for procedure calls and register saves. Small programs don't need large stack.

**Q: Why check overflow?**
A: 16-bit integers have limited range. Overflow causes incorrect results. Must detect and handle.

**Q: Why limit factorial to 8?**
A: 8! = 40320 fits in 16-bit signed range. 9! = 362880 exceeds 32767 (max signed 16-bit).

**Q: How does two-digit input work?**
A: Read first digit, store. Read second character. If Enter, single digit. Otherwise, calculate: first×10 + second.

**Q: Why use stack in print_number?**
A: Digits extracted in reverse order. Stack reverses them automatically for correct display order.

**Q: What is CWD instruction?**
A: Convert Word to Doubleword. Extends sign of AX into DX for signed division (dividend must be 32-bit).

**Q: Why preserve registers in procedures?**
A: Caller may have important values in registers. Procedures should not modify them unexpectedly.

**Q: Difference between MUL and IMUL?**
A: MUL is unsigned, IMUL is signed. This program uses IMUL to handle negative numbers correctly.

**Q: How does signed number input work?**
A: Check first character for '-'. If present, set flag. Build number digit by digit. Apply negation if flag set.

---

## 7. PROGRAM FLOW DIAGRAM

```
START
  ↓
Initialize DS
  ↓
MAIN_LOOP:
  Clear Screen
  Display Welcome & Menu
  ↓
GET_CHOICE:
  Read User Input (1-11)
  ↓
Validate Choice
  ↓
Is 11? → EXIT
  ↓
Is 9? → FACTORIAL
  ↓
Is 10? → SQUARE
  ↓
Is 6-8? → MEMORY_OPS
  ↓
Is 1-5? → ARITHMETIC
  Read num1, num2
  Perform Operation
  ↓
SHOW_RESULT
  ↓
CONTINUE_CHECK
  Continue? → MAIN_LOOP
  Exit? → END
```

---

## 8. MEMORY LAYOUT

```
Data Segment:
  - String messages (welcome, menu, prompts, errors)
  - Variables (num1, num2, result, memory, choice, sign_flag)
  - Operation symbols

Code Segment:
  - Main procedure
  - Arithmetic operations
  - Memory operations
  - Error handlers
  - Procedures (factorial, get_number, print_number)

Stack Segment:
  - Return addresses
  - Saved register values
  - Temporary storage
```

---

This explanation covers all aspects of the assembly calculator code. Study each section and understand the flow, register usage, and algorithm implementation for your viva examination.

