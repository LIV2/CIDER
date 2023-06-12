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
module Autoconfig (
    input [23:1] ADDR,
    input AS_n,
    input CLK,
    input RW,
    input [3:0] DIN,
    input RESET_n,
    input RAM_EN,
    input RANGER_EN,
    input ext_en,
    input OTHER_EN,
    input maprom_en,
    input mapram_en,
    input ide_enabled,
    input OVL,
    input [1:0] z2_state,
    output ram_access,
    output ide_access,
    output ctrl_access,
    output flash_access,
    output autoconfig_cycle,
    output reg [3:0] DOUT,
    output reg dtack
);

`include "globalparams.vh"

`define maprom
`ifndef makedefines
`define PRODID 8'd72
`endif

// Autoconfig
localparam [15:0] mfg_id  = 16'd5194;
localparam [31:0] serial  = 32'd1;

reg ram_configured;
reg ide_configured;
reg ctl_configured;

reg [2:0] ide_base;
reg [3:0] ctrl_base;
reg cdtv_configured;
reg cfgin;
reg cfgout;

reg [1:0] ac_state;

localparam ac_ram  = 2'b00,
           ac_ctl  = 2'b01,
           ac_ide  = 2'b10,
           ac_done = 2'b11;

wire [7:0] prodid [0:2];
assign prodid[ac_ram] = 8'd4;
assign prodid[ac_ide] = 8'h5;
assign prodid[ac_ctl] = 8'd6;

wire [3:0] boardSize [0:2];
assign boardSize[ac_ram] = 4'b0000; // 8M
assign boardSize[ac_ide] = 4'b0010; // 128K
assign boardSize[ac_ctl] = 4'b0001; // 64K

assign autoconfig_cycle = (ADDR[23:16] == 8'hE8) && cfgin && !cfgout;

// CDTV DMAC is first in chain.
// So we wait until it's configured before we talk
always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    cdtv_configured <= 0;
  end else begin
    if (ADDR[23:16] == 8'hE8 & ADDR[8:1] == 8'h24 & !AS_n & !RW) begin
      cdtv_configured <= 1'b1;
    end
  end
end

// These need to be registered at the end of a bus cycle
always @(posedge AS_n or negedge RESET_n) begin
  if (!RESET_n) begin
    cfgout <= 0;
    cfgin  <= 0;
  end else begin
    cfgin  <= cdtv_configured;
    cfgout <= (ac_state == ac_done);
  end
end

always @(posedge CLK or negedge RESET_n)
begin
  if (!RESET_n) begin
    DOUT           <= 'b0;
    ac_state       <= (RAM_EN) ? ac_ram : (ac_ram + 1);
    dtack          <= 0;
    ide_base       <= 3'b0;
    ctrl_base      <= 3'b0;
    ide_configured <= 0;
    ram_configured <= 0;
    ctl_configured <= 0;
  end else if (z2_state == Z2_DATA && autoconfig_cycle && !dtack) begin
    dtack <= 1;
    if (RW) begin
      case (ADDR[8:1])
        8'h00: 
          begin
            case (ac_state)
              ac_ram:  DOUT <= 4'b1110;                            // Memory / Link to free mem pool
              ac_ide:  DOUT <= {3'b110, ide_enabled};              // IO / Read from autoboot rom
              ac_ctl:  DOUT <= 4'b1100;                            // IO
            endcase
          end
        8'h01:   DOUT <= {boardSize[ac_state]};                    // Size: 8MB, 64K, 128K
        8'h02:   DOUT <= ~(prodid[ac_state][7:4]);                 // Product number
        8'h03:   DOUT <= ~(prodid[ac_state][3:0]);                 // Product number
        8'h04:   DOUT <= ~{ac_state == ac_ram ? 1 : 1'b0, 3'b000}; // Bit 1: Add to Z2 RAM space if set
        8'h05:   DOUT <= ~4'b0000;
        8'h08:   DOUT <= ~mfg_id[15:12];              // Manufacturer ID
        8'h09:   DOUT <= ~mfg_id[11:8];               // Manufacturer ID
        8'h0A:   DOUT <= ~mfg_id[7:4];                // Manufacturer ID
        8'h0B:   DOUT <= ~mfg_id[3:0];                // Manufacturer ID
        8'h0C:   DOUT <= ~serial[31:28];                           // Serial number
        8'h0D:   DOUT <= ~serial[27:24];                           // Serial number
        8'h0E:   DOUT <= ~serial[23:20];                           // Serial number
        8'h0F:   DOUT <= ~serial[19:16];                           // Serial number
        8'h10:   DOUT <= ~serial[15:12];                           // Serial number
        8'h11:   DOUT <= ~serial[11:8];                            // Serial number
        8'h12:   DOUT <= ~serial[7:4];                             // Serial number
        8'h13:   DOUT <= ~serial[3:0];                             // Serial number
        8'h14:   DOUT <= ~4'h0;                                    // ROM Offset high byte high nibble
        8'h15:   DOUT <= ~4'h0;                                    // ROM Offset high byte low nibble
        8'h16:   DOUT <= ~4'h0;                                    // ROM Offset low byte high nibble
        8'h17:   DOUT <= ~4'h8;                                    // ROM Offset low byte low nibble
        8'h20:   DOUT <= 4'b0;
        8'h21:   DOUT <= 4'b0;
        default: DOUT <= 4'hF;
      endcase
    end else begin
      if (ADDR[8:1] == 8'h26) begin
          // We've been told to shut up (not enough memory space)
          ac_state <= ac_state + 1;
      end else if (ADDR[8:1] == 8'h24) begin
          if (ac_state == ac_ram) begin
            ram_configured <= 1'b1;
          end
          ac_state <= ac_state + 1;
      end else if (ADDR[8:1] == 8'h25) begin
          if (ac_state == ac_ide) begin
            ide_configured <= 1'b1;
            ide_base <= DIN[3:1];
          end else if (ac_state == ac_ctl) begin
            ctl_configured <= 1'b1;
            ctrl_base <= DIN;
          end
      end
    end
  end else begin
    dtack <= 0;
  end
end

assign ide_access      = (ADDR[23:17] == {4'hE, ide_base} && ide_configured);

assign bonus_access    = (ADDR[23:16] >= 8'hA0) && (ADDR[23:16] <= 8'hBD); // A00000-BDFFFF Bonus RAM
assign mapram_access   = (ADDR[23:20] == 4'hF) && (!RW ^ mapram_en);       // F00000-FFFFFF Writes when MapRAM disabled or Reads when MapRAM enabled
assign rom_access      = (ADDR[23:20] == 4'hF) &&                          // F80000-FFFFFF
                         (ADDR[19] || ext_en) && RW && !mapram_en;         // F00000-F7FFFF (If A500 mode disabled)
assign boot_rom_access = (ADDR[23:20] == 4'b0000) && OVL;                  // 000000-0FFFFF When OVL = 1

assign flash_access    = (((rom_access || boot_rom_access) && maprom_en) || (bonus_access && !OTHER_EN));

assign otherram_access = bonus_access && OTHER_EN;

assign ranger_access   = (ADDR[23:16] >= 8'hC0) && (ADDR[23:16] <= 8'hD7) && RANGER_EN;

assign ram_access      = (ADDR[23:20] >= 4'h2 && ADDR[23:20] <= 4'h9) && ram_configured ||
                         mapram_access ||
                         otherram_access ||
                         ranger_access;

assign ctrl_access = (ADDR[23:16] == {4'hE,ctrl_base}) && ctl_configured;
endmodule
