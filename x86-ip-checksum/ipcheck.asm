;==============================================================================
; CSC35500 Programming Project 1 - IP address checksum
; Name: Callum Hudson
;
; What this program does:
;   1. Prints "Enter an IP address: " and reads what the user types.
;   2. Walks through the input one character at a time:
;        - digits are built up into a number (like 2, then 25, then 255)
;        - a dot (.) ends the current number
;        - a newline (Enter key) ends the whole input
;        - ANY other character (space, letter, slash, ...) makes it illegal
;   3. The address is legal only if it has exactly 4 numbers, exactly 3 dots,
;      every number has at least one digit, and no number is over 255.
;   4. If legal, it prints the checksum: for each number, (number % 31) - 15,
;      all added together.  Otherwise it prints "Illegal IP address".
;
; Build (same commands as the lecture slides):
;   nasm -gstabs -felf64 -l ipcheck.lst ipcheck.asm
;   ld ipcheck.o -o ipcheck
; Run:
;   ./ipcheck
;==============================================================================

          section .data
prompt:   db "Enter an IP address: "     ; 21 characters (no newline)
result:   db "The checksum is "          ; 16 characters
illegal:  db "Illegal IP address", 0xA   ; 19 characters (includes newline)
minus:    db "-"                         ; 1 character, for negative answers
newline:  db 0xA                         ; 1 character

; Variables the program keeps track of while it reads the input.
; dq = "define quadword" = 8 bytes (64 bits), starting at 0.
length:   dq 0      ; how many characters the read syscall gave us
num:      dq 0      ; the number we are currently building (e.g. 191)
digits:   dq 0      ; how many digits the current number has so far
dots:     dq 0      ; how many dots we have seen so far
total:    dq 0      ; running checksum total (can go negative)

          section .bss
buffer:   resb 256  ; "reserve" 256 bytes to hold what the user types
outBuf:   resb 32   ; room to build the checksum's digits for printing

          section .text
          global _start

_start:
;------------------------------------------------------------------------------
; Step 1: print the prompt and read the user's input
;------------------------------------------------------------------------------
          mov     rcx, prompt     ; address of the prompt text
          mov     rdx, 21         ; number of characters to print
          call    printString     ; print it (function at the bottom)

          mov     rax, 3          ; syscall 3 = read
          mov     rbx, 0          ; file 0 = stdin (the keyboard)
          mov     rcx, buffer     ; where to store the characters
          mov     rdx, 256        ; read at most 256 characters
          int     0x80            ; ask Linux to do the read
          mov     [length], rax   ; Linux returns the number of characters in RAX

          mov     rsi, 0          ; RSI = index of the character we're looking at

;------------------------------------------------------------------------------
; Step 2: look at each character, one at a time
;------------------------------------------------------------------------------
nextChar:
          cmp     rsi, [length]   ; have we looked at every character?
          jge     endOfInput      ; yes -> input is over

          mov     rax, 0          ; clear all 64 bits of RAX first...
          mov     al, [buffer+rsi]; ...then copy ONE character (1 byte) into AL

          cmp     al, 0xA         ; is it the newline from pressing Enter?
          je      endOfInput      ; yes -> input is over

          cmp     al, '.'         ; is it a dot?
          je      gotDot          ; yes -> finish the current number

          cmp     al, '0'         ; anything below '0' in the ASCII table...
          jl      badAddress      ; ...is not a digit -> illegal
          cmp     al, '9'         ; anything above '9' in the ASCII table...
          jg      badAddress      ; ...is not a digit -> illegal

; It's a digit.  Characters are stored as ASCII codes: '0' is 48, '1' is 49,
; ... '9' is 57.  Subtracting '0' (48) turns the character into its value.
          sub     al, '0'         ; e.g. '7' (55) - '0' (48) = 7
          mov     rbx, rax        ; save the digit's value in RBX

; New number = old number * 10 + digit.   Example: 19 then '1' -> 190 + 1 = 191
          mov     rax, [num]      ; RAX = number built so far
          mov     rcx, 10         ; MUL can't take a constant, so put 10 in RCX
          mul     rcx             ; RDX:RAX = RAX * 10 (overwrites RDX)
          add     rax, rbx        ; add the new digit
          mov     [num], rax      ; save the updated number
          inc     qword [digits]  ; one more digit in this number

          cmp     rax, 255        ; checked after EVERY digit, so a huge
          jg      badAddress      ; number can't get out of hand: >255 = illegal

          inc     rsi             ; move to the next character
          jmp     nextChar

;------------------------------------------------------------------------------
; Step 3: a dot ends the current number
;------------------------------------------------------------------------------
gotDot:
          cmp     qword [digits], 0 ; a dot with no digits before it?
          je      badAddress        ; (catches ".1.2.3" and "1..2.3") -> illegal

          call    addToChecksum   ; add (num % 31) - 15 to the total

          inc     qword [dots]    ; count this dot
          cmp     qword [dots], 3 ; more than 3 dots?
          jg      badAddress      ; -> illegal

          mov     qword [num], 0     ; start the next number fresh
          mov     qword [digits], 0
          inc     rsi             ; move past the dot
          jmp     nextChar

;------------------------------------------------------------------------------
; Step 4: input is over - make sure the address was complete
;------------------------------------------------------------------------------
endOfInput:
          cmp     qword [digits], 0 ; last number has no digits?
          je      badAddress        ; (catches "1.2.3." and empty input)
          cmp     qword [dots], 3   ; need exactly 3 dots (so 4 numbers)
          jne     badAddress

          call    addToChecksum   ; add the 4th (last) number

;------------------------------------------------------------------------------
; Step 5: print "The checksum is <total>" and a newline
;------------------------------------------------------------------------------
          mov     rcx, result
          mov     rdx, 16
          call    printString

          mov     rax, [total]    ; number to print goes in RAX
          call    printNumber

          mov     rcx, newline
          mov     rdx, 1
          call    printString
          jmp     exitProgram

badAddress:
          mov     rcx, illegal    ; print "Illegal IP address" + newline
          mov     rdx, 19
          call    printString

exitProgram:
          mov     rax, 1          ; syscall 1 = exit
          mov     rbx, 0          ; return value 0 = success
          int     0x80

;==============================================================================
; Functions
;==============================================================================

;------------------------------------------------------------------------------
; printString: prints RDX characters starting at address RCX.
;------------------------------------------------------------------------------
printString:
          mov     rax, 4          ; syscall 4 = write
          mov     rbx, 1          ; file 1 = stdout (the screen)
          int     0x80            ; RCX = address, RDX = length (set by caller)
          ret

;------------------------------------------------------------------------------
; addToChecksum: total = total + ((num % 31) - 15)
;------------------------------------------------------------------------------
addToChecksum:
          mov     rax, [num]      ; dividend goes in RAX
          mov     rdx, 0          ; DIV divides RDX:RAX, so RDX must be 0 first!
          mov     rbx, 31         ; DIV can't take a constant either
          div     rbx             ; RAX = num / 31, RDX = num % 31 (remainder)
          sub     rdx, 15         ; (num % 31) - 15   (may be negative)
          mov     rax, [total]
          add     rax, rdx        ; add it to the running total
          mov     [total], rax
          ret

;------------------------------------------------------------------------------
; printNumber: prints the signed number in RAX in decimal (e.g. -33 or 26).
;
; How: if negative, print "-" and flip it positive.  Then divide by 10 over and
; over; each remainder is one digit, but they come out backwards (last digit
; first).  Pushing them on the stack and popping them back off reverses them.
;------------------------------------------------------------------------------
printNumber:
          cmp     rax, 0          ; is the number negative?
          jge     notNegative

          push    rax             ; printString changes RAX, so save the number
          mov     rcx, minus
          mov     rdx, 1
          call    printString     ; print "-"
          pop     rax             ; get the number back

          mov     rbx, 0          ; flip the sign: 0 - number
          sub     rbx, rax        ; e.g. 0 - (-33) = 33
          mov     rax, rbx

notNegative:
          mov     rbx, 10         ; we divide by 10
          mov     rdi, 0          ; RDI counts how many digits we pushed
digitLoop:
          mov     rdx, 0          ; clear RDX before every DIV!
          div     rbx             ; RAX = RAX / 10, RDX = last digit (0-9)
          add     rdx, '0'        ; turn the digit into its ASCII character
          push    rdx             ; save it on the stack
          inc     rdi             ; one more digit
          cmp     rax, 0          ; anything left to divide?
          jne     digitLoop

          mov     rsi, 0          ; RSI = position in outBuf
popLoop:
          pop     rax             ; digits come back first-digit-first
          mov     [outBuf+rsi], al; store the character (1 byte)
          inc     rsi
          dec     rdi             ; one less digit left on the stack
          jnz     popLoop         ; keep going until all are popped

          mov     rcx, outBuf     ; print the digits
          mov     rdx, rsi        ; RSI = how many digits
          call    printString
          ret
