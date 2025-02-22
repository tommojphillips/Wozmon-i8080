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

BUFFER          SET 0200H           ; Text Input Buffer, Goes up
STACK_TOP       SET 01FEH           ; Top of stack, Goes down

SIO_STATUS      SET 010H            ; 2SIO Status Input Port
SIO_READ        SET 011H            ; 2SIO Read byte Input Port
SIO_WRITE       SET 011H            ; 2SIO Write byte Output Port

CR              SET 0DH
LF              SET 0AH
ESC             SET 01BH

                ORG 0D000H

RESET:          LXI SP, STACK_TOP
                LXI B, BUFFER + 07FH

NOTCR:          CPI '_'
                JZ BACKSPACE
                CPI ESC
                JZ ESCAPE
                INR C
                JP NEXTCHAR

ESCAPE:         MVI A, 05CH
                CALL ECHO
GETLINE:        MVI A, CR
                CALL ECHO
                MVI A, LF
                CALL ECHO
                MVI C, 1

BACKSPACE:      DCR C
                JM GETLINE

NEXTCHAR:       IN SIO_STATUS
                CPI 02H
                JZ NEXTCHAR
                IN SIO_READ
                STAX B
                CALL ECHO

                CPI CR
                JNZ NOTCR

                MVI A, LF
                CALL ECHO

                MVI C, 0FFH
                MVI A, 0
                MOV E, A
SETMODE:        STA MODE

BLSKIP:         INR C
NEXTITEM:       LDAX B

                CPI CR
                JZ GETLINE
                
                CPI '.'
                JC BLSKIP
                JZ SETMODE

                CPI ':'
                JZ SETMODE

                CPI 'R'
                JZ RUN

                MOV A, E
                STA LOW
                STA HIGH
                
                MOV A, C
                STA YSAV

NEXTHEX:        LDAX B
                XRI 030H
                CPI 0AH
                JC DIG
                ADI 089H
                CPI 0FAH
                JC NOTHEX
DIG:            RAL
                RAL
                RAL
                RAL
                ANI 0F0H

                MVI E, 04H
HEXSHIFT:       STC
                CMC
                RAL
                PUSH PSW
                LDA LOW
                RAL
                STA LOW
                LDA HIGH
                RAL
                STA HIGH
                POP PSW
                DCR E
                JNZ HEXSHIFT

                INR C
                JNZ NEXTHEX

NOTHEX:         LXI H, YSAV
                MOV A, C
                CMP M
                JZ ESCAPE
                
                LDA MODE
                CPI ':'
                JNZ NOTSTOR
                
                LDA LOW
                
                LHLD STL
                MVI D, 0
                DAD D
                MOV M, A
                
                LXI H, STL
                INR M
                
                JNZ NEXTITEM

                LXI H, STH
                INR M

TONEXTITEM:     JMP NEXTITEM

RUN:            LHLD XAML
                PCHL

NOTSTOR:        CPI 0H
                JNZ XAMNEXT
                
SETADR:         LDA LOW
                STA STL
                STA XAML
                
                LDA HIGH
                STA STH
                STA XAMH
               
NXTPRNT:        JNZ PRDATA

                MVI A, CR
                CALL ECHO
                MVI A, LF
                CALL ECHO
                
                LDA XAMH
                CALL PRBYTE
                
                LDA XAML
                CALL PRBYTE
                
                MVI A, ':'
                CALL ECHO

PRDATA:         MVI A, ' '
                CALL ECHO
                
                LHLD XAML
                MVI D, 0
                DAD D
                MOV A, M
                
                CALL PRBYTE

XAMNEXT:        LXI H, MODE
                MVI M, 0

                LDA XAML
                LXI H, LOW
                CMP M
                
                LDA XAMH
                LXI H, HIGH
                SBB M
                
                JNC TONEXTITEM
                
                LXI H, XAML
                INR M
                
                JNZ MOD8CHK
                
                LXI H, XAMH
                INR M

MOD8CHK:        LDA XAML
                ANI 07H
                JMP NXTPRNT

PRBYTE:         PUSH PSW          
                
                RAR
                RAR
                RAR
                RAR
                ANI 0FH
                
                CALL PRHEX
                POP PSW

PRHEX:          ANI 0FH
                ORI 030H
                CPI 03AH
                JC ECHO
                ADI 07H
ECHO:           OUT SIO_WRITE
                RET
