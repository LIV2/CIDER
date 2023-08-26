# CDTV IDE + RAM
IDE + 11.37 Megabyte Fast RAM + Dual Kickstart flash for the CDTV

![PCB](Docs/Render.png?raw=True)

## Features

- Plugs in to the Diagnostic port
- Autoboot IDE, Kick 1.3 compatible Open Source driver [lide.device](https://github.com/LIV2/lide.device)
- 11.37MB Fast RAM - 1.5MB $C0/Ranger + 8MB Fast + 1.87 Bonus ($A00000)
- Dual Kickstart Flash ROM with Extended ROM, programmable in-system

## Table of contents
1. [Compatibility](#compatibility)
2. [Quick start](#quick-start)
3. [Switch settings](#switch-settings)
    * [DIP Switches](#dip-switches)
    * [JP15](#jp15)
4. [Programming](#programming)
5. [Software](#software)
6. [Common issues](#common-issues)
7. [Ordering pcbs](#ordering-pcbs)
    * [PCB Order details](#pcb-order-details)
    * [PCB Assembly](#pcb-assembly)
    * [Bill of materials](#bill-of-materials)
8. [Acknowledgements](#acknowledgements)
9. [License](#license)

## Compatibility

Compatible with kickstart 1.3 and up.

## Quick start
* Remove the power cord from your CDTV
* Ensure the kick flash switch is turned off before using for the first time, all other dip-switches may be enabled if you wish
* Plug into the diag port in your CDTV
* Connect jumper-wire from CDTV JP15 and "To JP15" header, or remove the jumper from the CDTV's JP15 header
* Boot from the CIDER-IDE-Update.adf [here](https://github.com/LIV2/CIDER-Software/releases) to install the IDE ROM
* Download the software tools from the [CIDER-Software](https://github.com/LIV2/cider-software/releases) release page
* Consult the software [documentation](https://github.com/LIV2/CIDER-Software/blob/main/README.md)

## Switch settings
* A500 Mode: Disables the CDTV extended rom
* ROM Select: Selects the second bank of the Kickstart Flash when closed

### DIP Switches
1. Fast RAM enable
2. Ranger / $C0 RAM enable
3. IDE enable
4. Kick flash enable

### JP15
CIDER needs to disable the CDTV's own extended roms when in A500 mode, or when CIDER's Kick flash is enabled so that it can take over this function  
If you don't have a cable to connect this, you can simply remove the JP15 jumper (but the ext rom will then be disabled even if kick flash is switched off)

## Programming

Program the CPLD using this [jed file](https://github.com/LIV2/CIDER/raw/main/Binary/CIDER.jed) - You can find instructions on how to do that [here](https://linuxjedi.co.uk/2020/12/01/programming-xilinx-jtag-from-a-raspberry-pi/)

IDE ROM can be programmed by booting from the latest CIDER-IDE-Update.adf [here](https://github.com/LIV2/CIDER-Software/releases).

## Software

Various software tools for CIDER are available in the [CIDER-Software](https://github.com/LIV2/CIDER-Software) repository, you can find disk images and .lha files under the Releases section.

## Common issues

* **CDTV doesn't boot from IDE:** The original CDTV bootstrap does not boot from hard disks by default, only the builtin scsi.device, floppy or cdrom.  
To boot from the HDD I recommend making use of the 2.35 Extended rom from [CDTV Land](https://cdtvland.com/os235/)

## Ordering PCBs

Download the latest Gerbers.zip from the latest release listed on the right-hand side of this page.

Also included in the release are the placement and bom files needed for JLCPCB's assembly service

### PCB Order details
This PCB has been designed to JLCPCB's 4-layer capabilities so I recommend ordering from them

* Layers: 4
* Surface finish: ENIG
* Remove Order Number: Specify a location

### PCB Assembly
The release files include the relevant BOM and CPL files for JLCPCB's Assembly service  
You can use the following options:  
* PCBA Type: Economic
* Assembly side: Top side
* Tooling Holes: Added by Customer
* Confirm Parts Placement: Yes (I recommend checking that all ICs have pin 1 in the correct location etc)

### Bill of materials
|References|Qty|Value|Footprint|Link|Notes|
|----------|---|-----|---------|----|-----|
|CN1|1|CDTV Connector|KEL 8801-080-170S-F| |Contact KEL to order|
|C1,C3,C4,C6,C7,C8,C10,C11-14,C16-26,C28|23|0.1uF Ceramic|0603|[Mouser](https://www.mouser.com/ProductDetail/80-C603C104K5RAC3121)| |
|C2,C5,C27|3|47uF Tantalum|EIA-3216 KEMET A|[Mouser](https://www.mouser.com/ProductDetail/80-T490A476M10ATE1K)| |
|C9,C15|3|10uF Tantalum|EIA-3216 KEMET A|[Mouser](https://www.mouser.com/ProductDetail/581-TAJA106K016R)| |
|R2,R3,R5-12|10|10K|0603|[Mouser](https://www.mouser.com/ProductDetail/279-CRGH0603J10K)| |
|R13,R14|2|1K|0603|[Mouser](https://www.mouser.com/ProductDetail/791-WR06X102JTL)| |
|R1|1|33|0603|[Mouser](https://www.mouser.com/ProductDetail/279-CRG0603F33R)| |
|R4|1|220|0603|[Mouser](https://www.mouser.com/ProductDetail/71-CRCW0603-220-E3)| |
|D1|1|SMD LED|0603|[Mouser](https://www.mouser.com/ProductDetail/710-150060VS75003)| |
|U3-5|3|74HCT245|TSSOP-20|[Mouser](https://www.mouser.com/ProductDetail/595-SN74HCT245PWR)| |
|U6-7|3|74LVC245|TSSOP-20|[Mouser](https://www.mouser.com/ProductDetail/595-SN74LVC245APWR)| |
|U1|1|AZ1117CR-3.3|SOT-89-3|[Mouser](https://www.mouser.com/ProductDetail/621-AZ1117CR-3.3TRG1)| |
|U2|1|XC95144XL-10TQ100|TQFP-100|[Mouser](https://www.mouser.com/ProductDetail/217-5144XL-10TQG100C)|
|U8|1|8Mx16 SDRAM A3V28S40JTP-60|TSOP-II-54|[Mouser](https://www.mouser.com/ProductDetail/155-A3V28S40JTP-60)|Also suitable:</br> MT48LC8M16</br>W9812G6KH|
|U9|1|29F160|TSOP-I-48|[Mouser](https://www.mouser.com/ProductDetail/913-M29F160FB5AN6F2)| |
|U10|1|39SF010|TSOP-I-32|[Mouser](https://www.mouser.com/ProductDetail/804-39SF010A7CWHE)| |
|U11|1|74LVC1G32|SOT-23-5|[Mouser](https://www.mouser.com/ProductDetail/595-SN74LVC1G32DBVR)| |
|X1|1|50MHz Oscillator|3.2x2.5mm|[Mouser](https://www.mouser.com/ProductDetail/520-ECS-2333-500-BNT)| |
|F1|1|Polyfuse 1A trip, 500mA hold|1206|[Mouser](https://www.mouser.com/ProductDetail/576-1206L075/13.2WR)| |
|SW1|1|Omron A6H-4101|A6H-4101|[Mouser](https://www.mouser.com/ProductDetail/653-A6H-4101)| |
|RN1|1|10K|R Array Convex 4x0603|[Mouser](https://www.mouser.com/ProductDetail/667-EXB-V8V103GV)| |
|RN2-5|4|22 Ohm|R Array Convex 4x0603|[Mouser](https://www.mouser.com/ProductDetail/667-EXB-V8N220JV)| |
|J2-J3|2|Header|2.0mm 1x02 Right-angle| | |
|J5|1|Header|2.54mm 1x03 Right-angle| | |

## Acknowledgements

Thanks to [Stefan Reinauer](https://github.com/reinauer) for the idea to make a CDTV expansion, helping me to develop & test this and for sourcing some Connectors!  
The addition of the Kickstart Flash was inspired by [jbilander](https://github.com/jbilander)'s awesome [Spitfire 2000](https://github.com/jbilander/SF2000)  
Thank you to [Eriond](https://github.com/eriond) for providing the 3D Model of the KEL connector! 

## License
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

CIDER is licensed under the GPL-2.0 only license
