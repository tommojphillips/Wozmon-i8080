; The WOZ Monitor for the MITS Altair 8800
; Written by tommojphillips in 2025
; Github: https://github.com/tommojphillips/
; Originally Written by Steve Wozniak in 1976 for the Apple 1

; Page 0 Variables

XAML            SET 0024H           ;  Last "opened" location Low
XAMH            SET 0025H           ;  Last "opened" location High
STL             SET 0026H           ;  Store address Low
STH             SET 0027H           ;  Store address High
LOW             SET 0028H           ;  Hex value parsing Low
HIGH            SET 0029H           ;  Hex value parsing High
YSAV            SET 002AH           ;  Used to see if hex value is given
MODE            SET 002BH           ;  0 = XAM, ':' = STOR, '.' = BLOCK XAM

; Other Variables

BUFFER          SET 0200H           ; Text Input Buffer
STACK_TOP       SET 01FEH           ; Top of stack

SIO_STATUS      SET 010H            ; 88-SIO status/control port
SIO_DATA        SET 011H            ; 88-SIO read/write port

CR              SET 0DH             ; Carriage return char
LF              SET 0AH             ; Line feed char
ESC             SET 01BH            ; Escape char

                ORG 0D000H

RESET:          LXI SP, STACK_TOP
                LXI B, BUFFER + 07FH    ; BC =  200H + 7F

NOTCR:          CPI '_'         ; '_'?
                JZ BACKSPACE    ; Yes
                CPI 03H        ; 'CTRL-C'?
                JZ ESCAPE       ; Yes
                INR C           ; Advance text index
                JP NEXTCHAR     ; Auto ESC if > 127

ESCAPE:         MVI A, 05CH     ; '\'
                CALL ECHO       ; Output it
GETLINE:        MVI A, CR       ; CR
                CALL ECHO       ; Output it
                MVI A, LF       ; LF
                CALL ECHO       ; Output it
                MVI C, 1        ; Initialize text index

BACKSPACE:      DCR C           ; Back up text index
                JM GETLINE      ; Beyond start of line, reinitialize

NEXTCHAR:       IN SIO_STATUS   ; Input device ready?
                ANI 020H        ; DATA_AVAILABLE bit
                JZ NEXTCHAR     ; Loop until data available
                IN SIO_DATA     ; Get character
                STAX B          ; Add to text buffer
                CALL ECHO       ; Output character

                CPI CR          ; CR?
                JNZ NOTCR       ; No

                MVI A, LF       ; LF
                CALL ECHO       ; Output it

                MVI C, 0FFH     ; Reset text index
                MVI A, 0        ; For XAM mode
                MOV E, A        ; 0->X
SETMODE:        STA MODE        ; 0 = XAM, ':' = STOR, '.' = BLOCK XAM

BLSKIP:         INR C           ; Advance text index
NEXTITEM:       LDAX B          ; Get character

                CPI CR          ; CR?
                JZ GETLINE      ; Yes, done this line
                
                CPI '.'         ; "."?
                JC BLSKIP       ; Skip delimiter
                JZ SETMODE      ; Set BLOCK XAM mode

                CPI ':'         ; ":"?
                JZ SETMODE      ; Yes Set STOR mode

                CPI 'R'         ; "R"?
                JZ RUN          ; Yes Run user program

                MOV A, E
                STA LOW         ; 0->L
                STA HIGH        ; 0->H
                
                MOV A, C
                STA YSAV        ; Save Y for comparison

NEXTHEX:        LDAX B          ; Get character for hex test
                XRI 030H        ; Map digits to $0-9
                CPI 0AH         ; Digit?
                JC DIG          ; Yes
                ADI 089H        ; Map letter "A"-"F" to $FA-FF
                CPI 0FAH        ; Hex letter?
                JC NOTHEX       ; No, character not hex
DIG:            RAL
                RAL             ; Hex digit to MSD of A
                RAL
                RAL
                ANI 0F0H        ; Clear bottom nibble

                MVI E, 04H      ; Shift count
HEXSHIFT:       STC
                CMC
                RAL             ; Hex digit left, MSB to carry
                PUSH PSW
                LXI H, LOW
                MOV A, M
                RAL             ; Rotate into LSD
                MOV M, A
                INX H           ; LXI H, HIGH
                MOV A, M
                RAL             ; Rotate into MSD’s
                MOV M, A
                POP PSW
                DCR E           ; Done 4 shifts?
                JNZ HEXSHIFT    ; No, loop

                INR C           ; Advance text index
                JNZ NEXTHEX     ; Check next character for hex

NOTHEX:         LXI H, YSAV     ; Check if L, H empty (no hex digits)
                MOV A, C
                CMP M
                JZ ESCAPE       ; Yes, generate ESC sequence
                
                LDA MODE
                CPI ':'         ; Test for store MODE
                JNZ NOTSTOR
                
                LDA LOW         ; LSD’s of hex data
                
                LHLD STL        ; Get STORE LOW
                MOV M, A        ; Store at current ‘store index’
                
                LXI H, STL      ; Get STORE LOW
                INR M           ; Increment store index
                
                JNZ NEXTITEM    ; Get next item (no carry)

                INX H           ;LXI H, STH
                INR M           ; Add carry to ‘store index’ high order

                JMP NEXTITEM    ; Get next command item

RUN:            LHLD XAML       ; Run at current XAM index
                PCHL

NOTSTOR:        CPI 0H          ; Test MODE byte
                JNZ XAMNEXT     ; 00 for XAM, '.' for BLOCK XAM
                
SETADR:         LDA LOW         ; Copy hex data low
                STA STL         ; to ‘store index’
                STA XAML        ; to ‘XAM index’
                
                LDA HIGH        ; Copy hex data high
                STA STH         ; to ‘store index’
                STA XAMH        ; to ‘XAM index’
               
NXTPRNT:        JNZ PRDATA      ; NE means no address to print
                
                MVI A, CR       ; CR
                CALL ECHO       ; Output it
                MVI A, LF       ; LF
                CALL ECHO       ; Output it
                
                LDA XAMH        ; ‘Examine index’ high-order byte
                CALL PRBYTE     ; Output it in hex format
                
                LDA XAML        ; Low-order ‘examine index’ byte
                CALL PRBYTE     ; Output it in hex format
                
                MVI A, ':'      ; ":"
                CALL ECHO       ; Output it

PRDATA:         MVI A, ' '      ; Blank
                CALL ECHO       ; Output it
                
                LHLD XAML
                MOV A, M        ; Get data byte at ‘examine index’
                
                CALL PRBYTE     ; Output it in hex format

XAMNEXT:        LXI H, MODE     ; 0->MODE
                MVI M, 0

                LDA XAML
                LXI H, LOW
                CMP M           ; Compare ‘examine index’ to hex data
                
                LDA XAMH
                INX H           ;LXI H, HIGH
                SBB M
                
                JNC NEXTITEM    ; Not less, so no more data to output
                
                LXI H, XAML
                INR M
                
                JNZ MOD8CHK     ; Increment ‘examine index’
                
                INX H           ;LXI H, XAMH
                INR M

MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
                ANI 07H         ; For MOD 8=0
                JMP NXTPRNT     ; Always taken

PRBYTE:         PUSH PSW        ; Save A for LSD
                RAR
                RAR
                RAR             ; MSD to LSD position
                RAR
                ANI 0FH         ; Clear top nibble
                
                CALL PRHEX      ; Output hex digit
                POP PSW         ; Restore A

PRHEX:          ANI 0FH         ; Mask LSD for hex print
                ORI 030H        ; Add "0"
                CPI 03AH        ; Digit?
                JC ECHO         ; Yes, output it
                ADI 07H         ; Add offset for letter

ECHO:           PUSH PSW        ; Save character
ECHO_LOOP:      IN SIO_STATUS   ; Output device ready?
                RLC             ; OUTPUT_DEVICE_READY bit
                JC ECHO_LOOP    ; Loop until ready
                POP PSW         ; Restore character
                OUT SIO_DATA    ; Output character
                RET             ; Return
