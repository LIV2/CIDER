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

module IDE(
    input [23:12] ADDR,
    input UDS_n,
    input LDS_n,
    input RW,
    input AS_n,
    input CLK,
    input ide_access,
    input IORDY,
    input ide_enable,
    input RESET_n,
    output DTACK,
    output reg IOR_n,
    output reg IOW_n,
    output IDECS1_n,
    output IDECS2_n,
    output IDEBUF_OE,
    output IDE_ROMEN
    );

wire ds = !UDS_n || !LDS_n;

reg ide_dtack;
reg ide_enabled;

assign IDECS1_n = !(ide_access && ADDR[12]) || !ide_enabled;
assign IDECS2_n = !(ide_access && ADDR[13]) || !ide_enabled;

assign IDE_ROMEN = !(ide_access && !ide_enabled);

assign IDEBUF_OE = !(ide_access && ide_enabled && !AS_n);

reg [2:0] ds_delay;

always @(posedge CLK or posedge AS_n) begin
  if (AS_n) begin  
    IOW_n      <= 1;
    IOR_n      <= 1;
    ide_dtack  <= 0;
    ds_delay   <= 3'b000;
  end else begin
    ds_delay  <= {ds_delay[1:0],ds};
    ide_dtack <= ide_access && IORDY;
    
    IOR_n <= !(RW);

     // De-assert IOW ~100ns after UDS_n/LDS_n asserted
     // Data is latched on rising edge by drive, deasserting now ensures hold time met
    IOW_n <= !(!RW && !ds_delay[2]);
  end
end

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    ide_enabled <= 0;
  end else begin
    if (ide_access && ide_enable && !RW) ide_enabled <= 1;
  end
end
assign DTACK = ide_dtack;

endmodule
