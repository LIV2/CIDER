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
    input DIN,
    output reg DOUT,
    input [23:12] ADDR,
    input UDS_n,
    input LDS_n,
    input RW,
    input AS_n,
    input RESET_n,
    input CLK,
    input IDE_ENABLED,
    input IORDY,
    input INTREQ,
    input [1:0] z2_state,
    output INT2,
    output DTACK,
    output reg IOR_n,
    output reg IOW_n,
    output IDECS1_n,
    output IDECS2_n,
    output reg_access,
    output ide_access
    );

`include "globalparams.vh"

localparam gayle_id = 4'hD;

wire gid_reg;
wire gayle_reg;

wire ds = !UDS_n || !LDS_n;

reg [3:0] gid_shift = gayle_id; // Gayle ID Shift register

reg [2:0] INTREQ_sync; // INT request registered
reg int_enable;        // INT Enable
reg int_changed;       // INT Changed
reg int_clear;         // INT Change clear

reg reg_dtack;
reg ide_dtack;

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    INTREQ_sync <= 3'b000;
  end else begin
    INTREQ_sync[2:0] <= {INTREQ_sync[1:0],INTREQ};
  end
end

assign INT2 = IDE_ENABLED && int_changed && int_enable;

assign ide_access = (IDE_ENABLED && ADDR[23:15] == 'hDA0>>3); // $DA0000-DA7FFFF IDE

assign gid_reg    = (IDE_ENABLED && ADDR[23:15] == 'hDE1>>3); // $DE1000-DE1FFFF Gale ID
assign gayle_reg  = (IDE_ENABLED && ADDR[23:15] == 'hDA8>>3); // $DA8000-DAFFFFF Gayle registers
assign reg_access = (gid_reg || gayle_reg);


// Clear interrupts on reset or when interrupt clear register is written
always @(posedge CLK or posedge int_clear or negedge RESET_n) begin
  if (!RESET_n) begin
    int_changed <= 0;
  end else if (int_clear) begin
    int_changed <= 0;
  end else begin
    if (INTREQ_sync[2:1] == 2'b01) begin
      int_changed <= 1;
    end
  end
end


assign IDECS1_n = !(ide_access && !ADDR[12]);
assign IDECS2_n = !(ide_access && ADDR[12]);

reg [2:0] ds_delay;

always @(posedge CLK or posedge AS_n) begin
  if (AS_n) begin  
    IOW_n     <= 1;
    IOR_n     <= 1;
    ide_dtack <= 0;
    ds_delay  <= 3'b000;
  end else begin
    ds_delay  <= {ds_delay[1:0],ds};
    ide_dtack <= ide_access && IORDY;
    
    IOR_n <= !(ide_access && RW);

     // De-assert IOW ~100ns after UDS_n/LDS_n asserted
     // Data is latched on rising edge by drive, deasserting now ensures hold time met
    IOW_n <= !(ide_access && !RW && !ds_delay[2]);
  end
end

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    gid_shift <= gayle_id;
    int_enable <= 0;
    reg_dtack <= 0;
    int_clear <= 0;
  end else begin
    if (z2_state == Z2_DATA && reg_access && !reg_dtack) begin
      reg_dtack <= 1;
      if (RW) begin
        if (gayle_reg) begin
          case (ADDR[15:12])
            8'h8: // Interrupt request status
              DOUT <= INTREQ;
            8'h9: // Interrupt changed state
              DOUT <= int_changed;
            8'hA: // Interrupt enabled
              DOUT <= int_enable;
          endcase
        end else if (gid_reg) begin
          DOUT <= gid_shift[3]; // Gayle id bit
          gid_shift <= {gid_shift[2:0], 1'b1};
        end else begin
          DOUT <= 'b0;
        end
      end else begin
        if (gayle_reg) begin
          case (ADDR[15:12])
            8'hA:
              int_enable <= DIN; // Interrupt enable
            8'h9:
              int_clear <= 1;//~DIN; // Interrupt clear
          endcase
        end else if (gid_reg) begin
          gid_shift <= gayle_id; // On writes to Gayle ID register, reset the shift-register
        end
      end
    end else begin
      reg_dtack <= 0;
      int_clear <= 0;
    end
  end
end

assign DTACK = reg_dtack || ide_dtack;

endmodule
