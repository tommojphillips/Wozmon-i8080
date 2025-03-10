# Wozmon Intel 8080

An Adaption of Wozmon in intel 8080 assembly.

Input/Output is currently setup for for the MITS Altair 8800.

The Woz Monitor, also known as Wozmon, is a simple memory monitor and was the system software located in the 256 byte PROM on the Apple-1 from 1976. Wozmon is used to inspect and modify memory contents or to execute programs already located in memory.

The source code for the original Wozmon can be found here: https://github.com/jefftranter/6502/blob/master/asm/wozmon/wozmon.s

 - [Usage](#usage)
 - [Building](#building)
 - [Running](#running-wozmon)

## Usage

Wozmon operates and adheres to the same syntax as the original Wozmon on the Apple-1. The commands contain memory addresses and special characters for specifying whether to perform a read, write, or execute operation on them.

On startup Wozmon will display a backslash follow by a new line.

```
\
```

Wozmon will interpret any hex value as a memory address. If the provided hex value is greater then 4 digits, then the last 4 digits is used as the address.

Wozmon has 4 different modes.
 
 1. [Examine mode ](#examine-mode)
 2. [Block Examine mode](#block-examine-mode)
 3. [Store mode](#store-mode)
 4. [Execute mode](#executing-code)

 ### Examine mode
  Entering a hex value and pressing enter will display the 1 byte value at that address

```
\
E000

E000: 31
```

 ### Block Examine mode
 Entering a hex value followed by a `.` folowed by an hex value will display all bytes in that range.

```
\
E000.E01F

E000: 31 00 24 01 7F 02 FE 08
E008: CA 25 E0 FE 1B CA 14 E0
E010: 0C F2 29 E0 3E 5C CD 59
E018: E1 3E 0D CD 59 E1 3E 0A

```

 ### Store mode
  Entering a hex value followed by a `:` will allow you to write bytes starting at that memory address. Wozmon will show what the first byte at the starting address was before the write

```
\
0000:FF

0000: 00
0000

0000: FF
```

```
\
0000:FF FF FF FF FF FF FF FF

0000: 00
0000.000F

0000: FF FF FF FF FF FF FF FF
0008: 00 00 00 00 00 00 00 00
```

 ### Executing code

 Entering `R` will jump to the last examined address

```
\
E000 R

E000: 31[JUMP]
```
```
\
E000 

E000: 31
R[JUMP]
```

# Building

This project can be assembled using `ZASM by Megatokio`. 

#### ZASM - Z80, 8080 Assembler

https://github.com/Megatokio/zasm

```
zasm.exe --asm8080 -u -w wozmon.asm wozmon.bin
```

# Running Wozmon

 The project can be run using my own emulator, `Altair8800` or `Emu Studio`.
 
#### Altair8800

https://github.com/tommojphillips/Altair8800

  Loading wozmon:
 - Assemble Wozmon with ZASM or download a pre-compiled binary from [releases](https://github.com/tommojphillips/Wozmon-i8080/releases)
 - Use the following command to load wozmon at address `0xD000`

```
 Altair8800.exe -oD000 wozmon.bin
```

 ---

#### Emu Studio

https://github.com/emustudio/emuStudio

  Loading wozmon:
 - Start the emulator ( emuStudio.bat )
 - Select `MITS Altair8800`
 - Open and complie `wozmon.asm` in the source editor
 - Open the emulator tab
 - Open the device, `LSI ADM-3A termimal`
 - Run

 ---

You should see wozmon start up with the backslash `\`
