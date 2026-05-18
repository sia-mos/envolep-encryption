# Assembly Calculator - Quick Viva Reference

## PROGRAM STRUCTURE

### 1. Directives
- `.model small` - Small memory model (code ≤64KB, data ≤64KB)
- `.stack 100h` - 256 bytes stack space

### 2. Data Segment
- **Strings**: Messages with `13,10` (newline) and `'$'` (terminator)
- **Variables**: 
  - `dw` = 16-bit word (num1, num2, result, memory)
  - `db` = 8-bit byte (choice, sign_flag)

### 3. Main Program Flow
```
Initialize → Main Loop → Get Choice → Validate → Execute Operation → Display Result → Continue?
```

---

## KEY OPERATIONS

### Arithmetic (Options 1-5)
1. **Addition**: `add ax, num2` + overflow check (`jo`)
2. **Subtraction**: `sub ax, num2` + overflow check
3. **Multiplication**: `imul num2` → result in DX:AX, check DX≠0
4. **Division**: `cwd` (sign extend) → `idiv bx` → check divisor≠0
5. **Modulus**: Same as division, but result = remainder (DX)

### Special Operations
- **Factorial (9)**: Iterative: 1×2×3×...×n, limit n≤8 (8!=40320)
- **Square (10)**: `imul ax` (multiply by itself), check DX≠0

### Memory Operations (6-8)
- **M+ (6)**: `memory = memory + result`
- **MR (7)**: Display memory value
- **MC (8)**: `memory = 0`

---

## PROCEDURES

### 1. `get_number` - Read Signed Integer
**Algorithm:**
1. Check first char for '-' → set sign_flag
2. Read digits: `value = value × 10 + digit`
3. Stop on Enter (ASCII 13)
4. If sign_flag=1, negate: `neg ax`

**Example:** "-45" → flag=1, read 4→5, value=45, negate → -45

### 2. `print_number` - Display Signed Integer
**Algorithm:**
1. If negative: print '-', negate
2. Extract digits: divide by 10, push remainder on stack
3. Pop and print: convert to ASCII (`add dl, '0'`)

**Why stack?** Digits extracted in reverse, stack reverses them

### 3. `factorial` - Calculate n!
**Algorithm:**
- Special: 0! = 1, 1! = 1
- Loop: result = 1, multiply by 2, 3, ..., n
- Check overflow: `jo` after each multiply

---

## DOS INTERRUPTS (INT 21h)

| Function | AH | Purpose |
|----------|----|---------| 
| Read char | 01h | Input with echo, returns in AL |
| Print char | 02h | Output character in DL |
| Print string | 09h | Output string at DS:DX until '$' |
| Terminate | 4Ch | Exit program |

**BIOS Interrupt (INT 10h):**
- AH=00h, AL=03h: Clear screen (set video mode)

---

## REGISTER USAGE

| Register | Common Uses |
|----------|-------------|
| AX | Accumulator, arithmetic results, procedure return values |
| BX | Base register, temporary storage |
| CX | Counter (loops), temporary |
| DX | Data register, string offsets, division high word |
| DS | Data Segment (points to data) |
| SP | Stack Pointer |

---

## IMPORTANT INSTRUCTIONS

| Instruction | Purpose |
|-------------|---------|
| `mov` | Move/copy data |
| `add/sub` | Arithmetic operations |
| `imul` | Signed multiply (result in DX:AX) |
| `idiv` | Signed divide (dividend in DX:AX) |
| `cwd` | Convert word to doubleword (sign extend AX→DX) |
| `cmp` | Compare (sets flags, doesn't modify operands) |
| `je/jne/jl/jg` | Conditional jumps (Equal, Not Equal, Less, Greater) |
| `jo` | Jump if Overflow flag set |
| `call` | Call procedure (pushes return address) |
| `ret` | Return from procedure (pops return address) |
| `push/pop` | Stack operations (save/restore registers) |
| `lea` | Load Effective Address (get address of variable) |
| `neg` | Negate (two's complement) |
| `xor dx, dx` | Clear DX (faster than mov dx, 0) |

---

## FLAGS

- **OF (Overflow)**: Signed arithmetic exceeds range
- **ZF (Zero)**: Result is zero
- **SF (Sign)**: Result is negative
- **CF (Carry)**: Unsigned arithmetic overflow

---

## NUMBER RANGES

- **16-bit signed**: -32,768 to 32,767
- **16-bit unsigned**: 0 to 65,535
- **Factorial limit**: n ≤ 8 (8! = 40,320 fits, 9! = 362,880 doesn't)

---

## COMMON VIVA QUESTIONS

**Q: Why `.model small`?**
A: Code and data each ≤64KB, suitable for this program size.

**Q: Why stack in print_number?**
A: Digits extracted right-to-left, stack reverses for correct display.

**Q: Why CWD before division?**
A: Signed division needs 32-bit dividend (DX:AX). CWD extends sign.

**Q: Why limit factorial to 8?**
A: 8! = 40,320 fits in 16-bit. 9! = 362,880 exceeds 32,767.

**Q: How two-digit input works?**
A: Read first digit, read next char. If Enter→single digit, else: first×10+second.

**Q: Difference MUL vs IMUL?**
A: MUL unsigned, IMUL signed. Program uses IMUL for negative numbers.

**Q: Why preserve registers?**
A: Caller may need register values. Procedures shouldn't modify them.

**Q: How signed input works?**
A: Check '-', set flag, build number, negate if flag set.

**Q: Why check overflow?**
A: 16-bit range limited. Overflow causes wrong results. Must detect.

**Q: What is '$' in strings?**
A: DOS string terminator for INT 21h function 09h.

---

## PROGRAM FLOW SUMMARY

1. **Initialize**: Set DS register
2. **Main Loop**: Clear screen, show menu
3. **Input**: Get choice (1-11), validate
4. **Route**: 
   - 11 → Exit
   - 9 → Factorial (1 input)
   - 10 → Square (1 input)
   - 6-8 → Memory ops (no input)
   - 1-5 → Arithmetic (2 inputs)
5. **Execute**: Perform operation, check errors
6. **Display**: Show result
7. **Continue**: Ask user, loop or exit

---

## ERROR HANDLING

- **Invalid choice**: < 1 or > 11
- **Division by zero**: Check divisor before divide
- **Overflow**: Check OF flag or DX register
- **Negative factorial**: Factorial undefined for negatives
- **Factorial too large**: n > 8 exceeds 16-bit range

---

## MEMORY OPERATIONS

- **M+**: Accumulates results in memory variable
- **MR**: Recalls stored memory value
- **MC**: Clears memory to zero

---

## KEY ALGORITHMS

### Building Number from Digits
```
value = 0
for each digit:
    value = value × 10 + digit
```

### Extracting Digits for Display
```
while number > 0:
    digit = number % 10
    push digit
    number = number / 10
while stack not empty:
    pop digit
    print digit
```

### Factorial Calculation
```
result = 1
for i = 2 to n:
    result = result × i
```

---

## STUDY TIPS FOR VIVA

1. **Understand flow**: Trace execution path for each operation
2. **Know registers**: Which register used for what purpose
3. **Interrupts**: Memorize INT 21h functions (01h, 02h, 09h, 4Ch)
4. **Procedures**: How call/return works, register preservation
5. **Stack**: Why used, how push/pop works
6. **Overflow**: Why checked, how detected
7. **Signed operations**: How negatives handled
8. **Limitations**: Why factorial limited to 8, range restrictions

Good luck with your viva! 🎓

