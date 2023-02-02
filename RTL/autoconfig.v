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
    input CFGIN_n,
    input [3:0] DIN,
    input RESET_n,
    input RAM_EN,
    input RANGER_EN,
    input OTHER_EN,
    input maprom_en,
    input mapext_en,
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
`define SERIAL 32'd421
`define PRODID 8'd72
`endif

// Autoconfig
localparam [15:0] mfg_id  = 16'h07DB;
localparam [7:0]  prod_id = `PRODID;
localparam [31:0] serial = `SERIAL;

reg ram_configured;
reg ide_configured;
reg ctl_configured;

reg [3:0] ide_base;
reg [3:0] ctrl_base;
reg CFGOUT;

reg [1:0] ac_state;

localparam ac_ram  = 2'b00,
           ac_ide  = 2'b01,
           ac_ctl  = 2'b10,
           ac_done = 2'b11;

assign autoconfig_cycle = (ADDR[23:16] == 8'hE8) && !CFGIN_n && CFGOUT && RAM_EN;


always @(posedge AS_n or negedge RESET_n) begin
  if (!RESET_n) begin
    CFGOUT <= 1;
  end else begin
    CFGOUT <= ~(ac_state == ac_done);
  end
end

// Offers an 8MB block first, if there's no space offer 4MB, 2MB then 1MB before giving up
always @(posedge CLK or negedge RESET_n)
begin
  if (!RESET_n) begin
    DOUT           <= 'b0;
    ac_state       <= 0;
    dtack          <= 0;
    ide_base       <= 4'h0;
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
              ac_ram:  DOUT <= 2'b10; // Memory / Link to free mem pool
              ac_ide:  DOUT <= 2'b01; // IO / Read from autoboot rom
              ac_ctl:  DOUT <= 2'b00; // IO
            endcase
          end
        8'h01:   DOUT <= {3'b000, ac_state == ac_ram ? 1'b0 :  1'b1};  // Size: 8MB : 64KB
        8'h02:   DOUT <= ~prod_id[7:4]; // Product number
        8'h03:   DOUT <= ~{prod_id[3:2], ac_state}; // Product number
        8'h04:   DOUT <= ~{ac_state == ac_ram ? 1 : 1'b0, 3'b000};  // Bit 1: Add to Z2 RAM space if set
        8'h05:   DOUT <= ~4'b0000;
        8'h08:   DOUT <= ~mfg_id[15:12]; // Manufacturer ID
        8'h09:   DOUT <= ~mfg_id[11:8];  // Manufacturer ID
        8'h0A:   DOUT <= ~mfg_id[7:4];   // Manufacturer ID
        8'h0B:   DOUT <= ~mfg_id[3:0];   // Manufacturer ID
        8'h0C:   DOUT <= ~serial[31:28]; // Serial number
        8'h0D:   DOUT <= ~serial[27:24]; // Serial number
        8'h0E:   DOUT <= ~serial[23:20]; // Serial number
        8'h0F:   DOUT <= ~serial[19:16]; // Serial number
        8'h10:   DOUT <= ~serial[15:12]; // Serial number
        8'h11:   DOUT <= ~serial[11:8];  // Serial number
        8'h12:   DOUT <= ~serial[7:4];   // Serial number
        8'h13:   DOUT <= ~serial[3:0];   // Serial number
        8'h14:   DOUT <= ~4'h8;          // ROM Offset high byte high nibble
        /* These ones taken care of by the default case :)
        8'h15:   DOUT <= ~4'h0;         // ORM Offset high byte low nibble
        8'h16:   DOUT <= ~4'h0;         // ORM Offset low byte high nibble
        8'h17:   DOUT <= ~4'h0;         // ORM Offset low byte low nibble
        */
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
            ide_base <= DIN;
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

assign ide_access      = (ADDR[23:16] == {4'hE, ide_base} && ide_configured);

assign bonus_access    = (ADDR[23:16] >= 8'hA0) && (ADDR[23:16] <= 8'hBD);

assign rom_access      = (ADDR[23:19] == {4'hF,1'b1}) && maprom_en ||
                         (ADDR[23:20] == 4'b0000) && OVL && RW && maprom_en;
assign ext_access      = (ADDR[23:19] == {4'hF,1'b0}) && mapext_en;

assign flash_access    = ((rom_access || ext_access) || (bonus_access && !OTHER_EN));

assign otherram_access = bonus_access && OTHER_EN;

assign ranger_access   = (ADDR[23:16] >= 8'hC0) && (ADDR[23:16] <= 8'hD7) && RANGER_EN;

assign ram_access      = (ADDR[23:20] >= 4'h2 || ADDR[23:20] <= 4'h9) && ram_configured ||
                         otherram_access ||
                         ranger_access;

assign ctrl_access = (ADDR[23:16] == {4'hF,ctrl_base}) && ctl_configured;
endmodule
