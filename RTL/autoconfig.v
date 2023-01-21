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
    output ctrl_access,
    output ram_ovr,
    output autoconfig_cycle,
    output reg [3:0] DOUT,
    output reg dtack
);

`include "globalparams.vh"
reg [3:0] addr_match;

`define maprom
`ifndef makedefines
`define SERIAL 32'd421
`define PRODID 8'71
`endif

// Autoconfig
localparam [15:0] mfg_id  = 16'h07DB;
localparam [7:0]  prod_id = `PRODID;
localparam [31:0] serial = `SERIAL;


reg shutupram = 0;
reg configured;
reg CFGOUT;

reg [2:0] autoconfig_state;
localparam Offer_8M = 3'b000,
// If offering 2MB + 4MB blocks you need to offer the 2MB block first
// This is because of a kickstart bug where the memory config overflows if there is already 2MB configured before another 4MB then 2MB is configured...
`ifdef Offer_6M
        Offer_2M = 3'b001,
        Offer_4M = 3'b010,
`else
        Offer_4M = 3'b001,
        Offer_2M = 3'b010,
`endif
        SHUTUP   = 3'b011;

assign autoconfig_cycle = (ADDR[23:16] == 8'hE8) && !CFGIN_n && !CFGOUT && RAM_EN;


always @(posedge AS_n or negedge RESET_n) begin
  if (!RESET_n) begin
    CFGOUT <= 0;
  end else begin
    CFGOUT <= shutupram;
  end
end

// Offers an 8MB block first, if there's no space offer 4MB, 2MB then 1MB before giving up
always @(posedge CLK or negedge RESET_n)
begin
  if (!RESET_n) begin
    DOUT <= 'b0;
    configured <= 1'b0;
    shutupram <= 1'b0;
    addr_match <= 4'b0000;
    autoconfig_state <= Offer_8M;
    dtack <= 0;
  end else if (z2_state == Z2_DATA && autoconfig_cycle && !dtack) begin
    dtack <= 1;
    if (RW) begin
      case (ADDR[8:1])
        8'h00: DOUT <= 4'b1110;
        8'h01:
          begin
            case (autoconfig_state)
              Offer_8M: DOUT <= 4'b0000;
              Offer_4M: DOUT <= 4'b0111;
              Offer_2M: DOUT <= 4'b0110;
              default:  DOUT <= 4'b0000;
            endcase
          end
        8'h02:   DOUT <= ~prod_id[7:4]; // Product number
        8'h03:   DOUT <= ~prod_id[3:0]; // Product number
        8'h04:   DOUT <= ~4'b1000;
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

        8'h20:   DOUT <= 4'b0;
        8'h21:   DOUT <= 4'b0;
        default: DOUT <= 4'hF;
      endcase
    end else begin
      if (ADDR[8:1] == 8'h26) begin
          // We've been told to shut up (not enough memory space)
          // Try offering a smaller block
          if (autoconfig_state >= SHUTUP-1) begin
            // All options exhausted - time to shut up!
            shutupram <= 1;
            autoconfig_state <= SHUTUP;
          end else begin
            // Offer the next smallest block
            autoconfig_state <= autoconfig_state + 1;
          end
      end else if (ADDR[8:1] == 8'h24) begin
        case (autoconfig_state)
          Offer_8M:
            begin
              addr_match <= 4'hF;
              shutupram  <= 1'b1;
            end
          Offer_4M:
            begin
              case(DIN)
                4'h2:    addr_match <= (addr_match|4'b0011);
                4'h4:    addr_match <= (addr_match|4'b0110);
                4'h6:    addr_match <= (addr_match|4'b1100);
              endcase
              shutupram  <= 1'b1;
            end
          Offer_2M:
            begin
              case(DIN)
                4'h2:    addr_match <= (addr_match|4'b0001);
                4'h4:    addr_match <= (addr_match|4'b0010);
                4'h6:    addr_match <= (addr_match|4'b0100);
                4'h8:    addr_match <= (addr_match|4'b1000);
              endcase
              `ifdef Offer_6M
              autoconfig_state <= Offer_4M;
              `else
              shutupram <= 1'b1;
              `endif
            end
          default: addr_match <= 4'b0;
        endcase
        configured <= 1'b1;
      end
    end
  end else begin
    dtack <= 0;
  end
end

assign rom_access         = (ADDR[23:19] == {4'hF,1'b1}) && (RW == maprom_en) ||
                            (ADDR[23:20] == 4'b0000) && OVL && RW && maprom_en;
assign ext_access         = (ADDR[23:19] == {4'hF,1'b0}) && (RW == mapext_en);

assign otherram_access = (ADDR[23:16] >= 8'hA0) && (ADDR[23:16] <= 8'hBD) && OTHER_EN;
assign ranger_access   = (ADDR[23:16] >= 8'hC0) && (ADDR[23:16] <= 8'hD7) && RANGER_EN;

assign ram_ovr = otherram_access ||
       ranger_access             ||
       (rom_access && maprom_en) ||
       (ext_access && mapext_en);

assign ram_access = ((
      ((ADDR[23:21] == 3'b001) & addr_match[0]) ||
      ((ADDR[23:21] == 3'b010) & addr_match[1]) ||
      ((ADDR[23:21] == 3'b011) & addr_match[2]) ||
      ((ADDR[23:21] == 3'b100) & addr_match[3])
      ) & configured)    ||
      otherram_access    ||
      ranger_access      || 
      rom_access         ||
      ext_access;

assign ctrl_access = (ADDR[23:16] == 8'hEF);
endmodule
