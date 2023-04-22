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
 module ControlReg (
    input AS_n,
    input [23:16] ADDR,
    input [15:12] DIN,
    input CLK,
    input ctrl_access,
    input flash_enabled,
    input flash_bank,
    input RW,
    input [1:0] z2_state,
    input RESET_n,
    output flash_a18,
    output flash_a19,
    output [3:0] DOUT,
    output reg otherram_en,
    output reg mapram_en,
    output reg OVL
);

`include "globalparams.vh"

reg dtack;
reg flash_progbank;

assign flash_a19 = (flash_enabled && !mapram_en) ? flash_bank : flash_progbank;

// Force Flash to Kick rather than Ext rom during early boot access.
assign flash_a18 = (OVL && !ADDR[23]) ? 1'b1 : ADDR[19];

assign DOUT[3] = flash_bank;
assign DOUT[2] = flash_enabled & !mapram_en;
assign DOUT[1] = otherram_en;
assign DOUT[0] = 0;

always @(posedge CLK or negedge RESET_n)
    if (!RESET_n) begin
        flash_progbank  <= 0;
        mapram_en       <= 0;
        otherram_en     <= 0;
        OVL             <= 1;
        dtack           <= 0;
    end else begin
        if (ADDR[23:16] == 8'hBF && !RW && !AS_n)
            OVL <= 0; // Write to CIA seen, time to disable early boot overlay

        if (z2_state == Z2_DATA && !dtack && ctrl_access) begin
            if (!RW) begin
                if (DIN[12]) begin
                    flash_progbank  <= flash_progbank | DIN[15];
                    mapram_en       <= mapram_en      | DIN[14];
                    otherram_en     <= otherram_en    | DIN[13];
                end else begin
                    flash_progbank  <= flash_progbank & ~DIN[15];
                    otherram_en     <= otherram_en    & ~DIN[13];
                end
            end
            dtack <= 1;
        end else begin
            dtack <= 0;
        end
    end
endmodule
