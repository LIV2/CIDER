# CDTV IDE + RAM
IDE + 11.37 Megabyte Fast RAM + Dual Kickstart flash for the CDTV

![PCB](Docs/Render.png?raw=True)

## Features

- Plugs in to the Diagnostic port
- Autoboot IDE, Kick 1.3 compatible Open Source driver [lide.device](https://github.com/LIV2/lide.device)
- 11.37MB Fast RAM - 1.5MB $C0/Ranger + 8MB Fast + 1.87 Bonus ($A00000)
- Dual Kickstart Flash ROM with Extended ROM, programmable in-system

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

## Programming

Program the CPLD using this [jed file](https://github.com/LIV2/CIDER/raw/main/Binary/CIDER.jed) - You can find instructions on how to do that [here](https://linuxjedi.co.uk/2020/12/01/programming-xilinx-jtag-from-a-raspberry-pi/)

IDE ROM can be programmed by booting from the latest CIDER-IDE-Update.adf [here](https://github.com/LIV2/CIDER-Software/releases).

## Software

Various software tools for CIDER are available in the [CIDER-Software](https://github.com/LIV2/CIDER-Software) repository, you can find disk images and .lha files under the Releases section.

## Common issues

* **CDTV doesn't boot from IDE:** The original CDTV bootstrap does not boot from hard disks by default, only the builtin scsi.device, floppy or cdrom.  
To boot from the HDD I recommend making use of the 2.35 Extended rom from [CDTV Land](https://cdtvland.com/os235/)

## Acknowledgements

Thanks to [Stefan Reinauer](https://github.com/reinauer) for the idea to make a CDTV expansion, helping me to develop & test this and for sourcing some Connectors!  
The addition of the Kickstart Flash was inspired by [jbilander](https://github.com/jbilander)'s awesome [Spitfire 2000](https://github.com/jbilander/SF2000)  
Thank you to [Eriond](https://github.com/eriond) for providing the 3D Model of the KEL connector! 

## License
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

CIDER is licensed under the GPL-2.0 only license
