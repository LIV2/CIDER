# CFLASH

A tool to program the Kickstart and IDE Flash of the CIDER board.

## Usage
```
    Usage: cflash [-fieEvV] [-c|-f <kickstart rom>] [-0|1]  -s [0|1]
           -c                  -  Copy physical ROM to Flash.
           -f <kickstart file> -  Kickstart file to Flash or verify.
           -i                  -  Print Flash device id.
           -I <ide rom file>   -  Flash IDE ROM.
           -e                  -  Erase bank.
           -E                  -  Erase chip.
           -v                  -  Verify bank against file or ROM
           -V                  -  Skip verification after programming.
           -0                  -  Select bank 0 - $FO Extended ROM.
           -1                  -  Select bank 1 - $F8 Kickstart ROM.
           -s [0|1]            -  Select kickstart slot to work on.
```