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
module Interrupt (
  input CLK,
  input RESET_n,
  input [23:1] ADDR,
  input D15,
  input D14,
  input DIN,
  input AS_n,
  input LDS_n,
  input UDS_n,
  input RW,
  input ide_int,
  input [2:0] ipl_in,
  output [2:0] ipl_out,
  output reg intreq_override
);

reg int_reg_ack;
reg int_master_en;
reg int2_enable;
reg int2;

assign custom_access = (ADDR[23:16] == 8'hDF);

wire intreqr_access = (ADDR[11:1] == 11'b00000001111); // $DFx01E
wire intena_access  = (ADDR[11:1] == 11'b00001001101); // $DFx09A

always @(posedge CLK or negedge RESET_n)
begin
  if (!RESET_n) begin
    int2_enable     <= 0;
    int_master_en   <= 0;
    intreq_override <= 0;
    int_reg_ack     <= 0;
    int2            <= 0;
  end else begin
    int2 <= ide_int && int2_enable && int_master_en;

    if (custom_access & !AS_n) begin
      if (intena_access && !RW && !int_reg_ack && (!UDS_n || !LDS_n)) begin
        // INTENA register
        // Bit 15: Set/clear
        // Bit 14: Master enable
        // Bit 3: INT2
        int_reg_ack <= 1;
        if (DIN)
          int2_enable <= D15;
        if (D14)
          int_master_en <= D15;
        
      end else if (intreqr_access && RW && int2) begin
        intreq_override <= 1;
      end 
    end else begin
      intreq_override <= 0;
      int_reg_ack     <= 0;
    end
  end
end

assign ipl_out[2:0] = {int2 && (ipl_in == 3'b111 || ipl_in == 3'b110)} ? 3'b101 : ipl_in[2:0];

endmodule