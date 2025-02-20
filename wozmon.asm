;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976

; Adapted instructions for the intel 8080
; Written by tommojphillips in 2025

; Page 0 Variables

XAML            SET 0024H           ;  Last "opened" location Low
XAMH            SET 0025H           ;  Last "opened" location High
STL             SET 0026H           ;  Store address Low
STH             SET 0027H           ;  Store address High
LOW             SET 0028H           ;  Hex value parsing Low
HIGH            SET 0029H           ;  Hex value parsing High
YSAV            SET 002AH           ;  Used to see if hex value is given
MODE            SET 002BH           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM


; Other Variables

BUFFER          SET 0200H

SIO_STATUS      SET 010H
SIO_WRITE       SET 011H
SIO_READ        SET 011H

CR              SET 0DH
LF              SET 0AH

                ORG 0E000H

RESET:          LXI SP, 02400H
                LXI B, BUFFER + 07FH    ; BC =  200H + 7F

NOTCR:          CPI 08H         ; 'backspace'?
                JZ BACKSPACE    ; Yes
                CPI 01BH        ; 'ESC'?
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

NEXTCHAR:       IN SIO_STATUS   ; Key ready?
                CPI 02H
                JZ NEXTCHAR     ; Loop until ready
                IN SIO_READ     ; Get character      
                STAX B          ; Add to text buffer
                CALL ECHO       ; Display character

                CPI CR          ; CR?
                JNZ NOTCR       ; No

                MVI A, LF       ; LF
                CALL ECHO

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

DIG:            STC
                CMC             ; Clear carry
                RAL             ; Shift left
                STC
                CMC             ; Clear carry
                RAL             ; Hex digit to MSD of A
                STC
                CMC             ; Clear carry
                RAL             ; Shift left
                STC
                CMC             ; Clear carry
                RAL             ; Shift left

                MVI E, 04H      ; Shift count
HEXSHIFT:       STC
                CMC
                RAL             ; Hex digit left, MSB to carry

                PUSH PSW

                LDA LOW
                RAL             ; Rotate into LSD
                STA LOW

                LDA HIGH
                RAL             ; Rotate into MSD’s
                STA HIGH
               
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
                
                LDA 028H        ; ASSEMBLER BUG - LOW '28H' ASSEMBLES TO '09H' - ;LOW         ; LSD’s of hex data
                
                LHLD STL        ; Get STORE LOW
                MVI D, 0
                DAD D           ; STL + X
                MOV M, A        ; Store at current ‘store index’
                
                LXI H, STL      ; Get STORE LOW
                INR M           ; Increment store index
                
                JNZ NEXTITEM    ; Get next item (no carry)

                LXI H, STH
                INR M           ; Add carry to ‘store index’ high order

TONEXTITEM:     JMP NEXTITEM    ; Get next command item

RUN:            LHLD XAML       ; Run at current XAM index
                PCHL

NOTSTOR:        CPI 0H          ; Test MODE byte
                JNZ XAMNEXT     ; 00 for XAM, '.' for BLOCK XAM
                
SETADR:         LDA LOW
                STA STL
                STA XAML
                
                LDA HIGH
                STA STH
                STA XAMH
               
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
                MVI D, 0
                DAD D
                MOV A, M        ; Get data byte at ‘examine index’
                
                CALL PRBYTE     ; Output it in hex format

XAMNEXT:        LXI H, MODE     ; 0->MODE
                MVI M, 0

                LDA XAML
                LXI H, LOW
                CMP M           ; Compare ‘examine index’ to hex data
                
                LDA XAMH
                LXI H, HIGH
                SBB M
                
                JNC TONEXTITEM  ; Not less, so no more data to output
                
                LXI H, XAML
                INR M
                
                JNZ MOD8CHK     ; Increment ‘examine index’
                
                LXI H, XAMH
                INR M

MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
                ANI 07H         ; For MOD 8=0
                JMP NXTPRNT     ; Always taken

PRBYTE:         PUSH PSW        ; Save A for LSD                
                
                STC
                CMC             ; Clear carry
                RAR             ; Shift right

                STC
                CMC             ; Clear carry
                RAR             ; Shift right

                STC
                CMC             ; Clear carry
                RAR             ; MSD to LSD position

                STC
                CMC             ; Clear carry
                RAR             ; Shift right   
                
                CALL PRHEX      ; Output hex digit
                POP PSW         ; Restore A

PRHEX:          ANI 0FH         ; Mask LSD for hex print
                ORI 030H        ; Add "0"
                CPI 03AH        ; Digit?
                JC ECHO         ; Yes, output it
                ADI 07H         ; Add offset for letter
ECHO:           OUT SIO_WRITE   ; Output character
                RET             ; Return

