`timescale 1ns / 1ps
/*
 * Copyright (C) 2023 Matthew Harlum <matt@harlum.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
module CIDER(
    inout [15:12] DBUS,
    input [23:1] ADDR,
    input BERR_n,
    input UDS_n,
    input LDS_n,
    input RW,
    inout AS_n,
    input RESET_n,
    input ECLK,
    output DTACK_n,
    output OVR_n,
// IDE stuff
    input IDEEN_n,
    input IORDY,
    output IOR_n,
    output IOW_n,
    output IDECS1_n,
    output IDECS2_n,
    output IDEBUF_OE,
    output IDE_ROMEN,
// SDRAM Stuff
    input CFGIN_n,
    input MEMCLK,
    input RAM_EN_n,
    input RANGER_EN_n,
    output MEMW_n,
    output RAS_n,
    output CAS_n,
    output CKE,
    output DQML,
    output DQMH,
    output RAMCS_n,
    output [11:0] MA,
    output [1:0] BA,
    output RAMOE_n,
// FLASH Stuff
    input FLASH_BANK_SEL,
    input FLASH_EN_n,
    output FLASH_CE_n,
    output FLASH_A18,
    output FLASH_A19
    );

`include "globalparams.vh"

wire autoconfig_cycle;
wire ctrl_access;
wire flash_access;
wire [3:0] autoconfig_dout;
wire [3:0] ctrl_dout;
wire ide_dtack;
wire ram_dtack;
wire autoconf_dtack;

reg dtack;
reg flash_enabled;
reg flash_bank;

wire ram_access;
wire ide_access;

wire otherram_enabled;

localparam RAM_FAST_RANGER_OTHER = 2'b11,
           RAM_FAST_RANGER       = 2'b10,
           RAM_FAST              = 2'b01,
           RAM_DISABLED          = 2'b00;

always @(posedge MEMCLK) begin
  if (!RESET_n) begin
    flash_bank <= FLASH_BANK_SEL;
    flash_enabled <= ~FLASH_EN_n;
  end
end

reg [1:0] UDS_n_sync;
reg [1:0] LDS_n_sync;
reg [2:0] AS_n_sync;
reg [1:0] RW_sync;

always @(posedge MEMCLK or negedge RESET_n) begin
  if (!RESET_n) begin
    UDS_n_sync <= 2'b11;
    LDS_n_sync <= 2'b11;
    AS_n_sync  <= 3'b111;
    RW_sync    <= 2'b11;
  end else begin
    UDS_n_sync[1:0] <= {UDS_n_sync[0],UDS_n};
    LDS_n_sync[1:0] <= {LDS_n_sync[0],LDS_n};
    AS_n_sync[2:0]  <= {AS_n_sync[1:0],AS_n};
    RW_sync         <= {RW_sync[0],RW};
  end
end

reg [1:0] z2_state;

always @(posedge MEMCLK or negedge RESET_n) begin
  if (!RESET_n) begin
    z2_state <= Z2_IDLE;
    dtack    <= 0;
  end else begin
    case (z2_state)
      Z2_IDLE:
        begin
          dtack <= 0;
          if (~AS_n_sync[2] && (ctrl_access || ram_access || ide_access || autoconfig_cycle || flash_access)) begin
            z2_state <= Z2_START;
          end
        end
      Z2_START:
        begin
          if (!UDS_n_sync[1] || !LDS_n_sync[1]) begin
            z2_state <= Z2_DATA;
          end
        end
      Z2_DATA:
        begin
          if (ctrl_access || ram_dtack || autoconf_dtack || ide_dtack || flash_access) begin
            dtack <= 1'b1;
            z2_state <= Z2_END;
          end
        end
      Z2_END:
        if (AS_n_sync[1]) begin
          dtack <= 0;
          z2_state <= Z2_IDLE;
        end
    endcase
  end
end

Autoconfig AUTOCONFIG (
  .ADDR (ADDR),
  .AS_n (AS_n_sync[1]),
  .RW (RW_sync[1]),
  .CLK (MEMCLK),
  .CFGIN_n (CFGIN_n),
  .DIN (DBUS[15:12]),
  .RESET_n (RESET_n),
  .ram_access (ram_access),
  .RAM_EN (~RAM_EN_n),
  .RANGER_EN (~RANGER_EN_n),
  .OTHER_EN (otherram_enabled),
  .autoconfig_cycle (autoconfig_cycle),
  .DOUT (autoconfig_dout),
  .z2_state (z2_state),
  .dtack (autoconf_dtack),
  .maprom_en (~FLASH_EN_n),
  .mapext_en (~FLASH_EN_n),
  .ctrl_access (ctrl_access),
  .ide_access (ide_access),
  .flash_access (flash_access),
  .OVL (OVL)
);

SDRAM SDRAM (
  .ADDR (ADDR[23:1]),
  .z2_state (z2_state),
  .UDS_n (UDS_n_sync[1]),
  .LDS_n (LDS_n_sync[1]),
  .RAM_CYCLE (ram_access),
  .RESET_n (RESET_n),
  .RW (RW_sync[1]),
  .CLK (MEMCLK),
  .CKE (CKE),
  .BA (BA),
  .MADDR (MA),
  .CAS_n (CAS_n),
  .RAS_n (RAS_n),
  .CS_n (RAMCS_n),
  .WE_n (MEMW_n),
  .DQML (DQML),
  .DQMH (DQMH),
  .dtack (ram_dtack),
  .ECLK (ECLK)
);

IDE IDE (
  .ADDR (ADDR[23:12]),
  .UDS_n (UDS_n_sync[1]),
  .LDS_n (LDS_n_sync[1]),
  .RW (RW),
  .AS_n (AS_n_sync[2]),
  .CLK (MEMCLK),
  .IORDY (IORDY),
  .DTACK (ide_dtack),
  .IOR_n (IOR_n),
  .IOW_n (IOW_n),
  .IDECS1_n (IDECS1_n),
  .IDECS2_n (IDECS2_n),
  .ide_access (ide_access),
  .ide_enabled (IDEEN_n),
  .IDE_ROMEN (IDE_ROMEN)
);

ControlReg ControlReg (
  .ADDR (ADDR[23:16]),
  .DIN (DBUS[15:12]),
  .DOUT (ctrl_dout),
  .CLK (MEMCLK),
  .ctrl_access (ctrl_access),
  .RW (RW_sync[1]),
  .AS_n (AS_n_sync[1]),
  .z2_state (z2_state),
  .RESET_n (RESET_n),
  .otherram_en (otherram_enabled),
  .flash_enabled (flash_enabled),
  .flash_a18  (FLASH_A18),
  .flash_a19  (FLASH_A19),
  .flash_bank (flash_bank),
  .OVL (OVL)
);

assign DBUS[15:12] = (autoconfig_cycle || ctrl_access) && RW && !UDS_n && RESET_n ? (autoconfig_cycle) ? autoconfig_dout : ctrl_dout : 'bZ;

assign RAMOE_n = !(ram_access && !AS_n && RESET_n);

assign FLASH_CE_n = !(flash_access && !AS_n);

wire RAM_OVR = (ctrl_access || ram_access || autoconfig_cycle && !AS_n);
wire IDE_OVR = (ide_access && !AS_n);

assign OVR_n   = (IDE_OVR || RAM_OVR || flash_access) ? 1'b0 : 1'bZ;
assign DTACK_n = (dtack && (IDE_OVR || RAM_OVR || flash_access)) ? 1'b0 : 1'bZ;

assign IDEBUF_OE = !(ide_access && !AS_n && RESET_n);

endmodule
