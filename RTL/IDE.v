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
    input RW,
    input AS_n,
    input CLK,
    input ide_access,
    input IORDY,
    input ide_enable,
    input RESET_n,
    output IDECS1_n,
    output IDECS2_n,
    output IDEBUF_OE,
    output IDE_ROMEN
    );

reg ide_enabled;

assign IDECS1_n = !(ide_access && ADDR[12] && !ADDR[16]) || !ide_enabled;
assign IDECS2_n = !(ide_access && ADDR[13] && !ADDR[16]) || !ide_enabled;

assign IDE_ROMEN = !(ide_access && (!ide_enabled || ADDR[16]));

assign IDEBUF_OE = !(ide_access && ide_enabled && !ADDR[16] && (!AS_n || !RW));

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    ide_enabled <= 0;
  end else begin
    if (ide_access && ide_enable && !RW) ide_enabled <= 1;
  end
end

endmodule
