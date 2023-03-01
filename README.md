# CDTV IDE + RAM
IDE + 11.37 Megabyte Fast RAM + Dual Kickstart flash for the CDTV

![PCB](Docs/Render.png?raw=True)

## Features
- Plugs in to the Diagnostic port
- Autoboot IDE, Kick 1.3 compatible
- 11.37MB Fast RAM - 1.5MB $C0/Ranger + 8MB Fast + 1.87 Bonus ($A00000)
- Dual Kickstart Flash ROM with Extended ROM, programmable in-system

## Ordering PCBs

Download the latest Gerbers.zip from the latest release listed on the right-hand side of this page.

Also included in the release are the placement and bom files needed for JLCPCB's assembly service

## Programming

Program the CPLD using this [jed file](https://github.com/LIV2/CIDER/raw/main/Binary/CIDER.jed) - You can find instructions on how to do that [here](https://linuxjedi.co.uk/2020/12/01/programming-xilinx-jtag-from-a-raspberry-pi/)

IDE ROM can be programmed by disabling IDE and booting from the latest CIDER-IDE-Update.adf [here](https://github.com/LIV2/CIDER-Software/releases).

## Software
Various software tools for CIDER are available in the [CIDER-Software](https://github.com/LIV2/CIDER-Software) repository, you can find disk images and .lha files under the Releases section.


## License
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)


CIDER is licensed under the GPL-2.0 only license