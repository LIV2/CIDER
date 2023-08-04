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
module SDRAM(
    input [23:1] ADDR,
    input [1:0] z2_state,
    input UDS_n,
    input LDS_n,
    input RAM_CYCLE,
    input RESET_n,
    input RW,
    input CLK,
    input ECLK,
    output reg [1:0] BA,
    output reg [11:0] MADDR,
    output reg CAS_n,
    output reg RAS_n,
    output reg CS_n,
    output reg WE_n,
    output reg CKE,
    output reg DQML,
    output reg DQMH,
    output reg dtack
    );

`include "globalparams.vh"

`define cmd(ARG) \
{RAS_n, CAS_n, WE_n} <= ARG;

localparam tRP = 1;
localparam tRCD = 1;
localparam tRFC = 3;
localparam CAS_LATENCY = 3'd2;

// RAS CAS WE
localparam cmd_nop             = 3'b111,
           cmd_active          = 3'b011,
           cmd_read            = 3'b101,
           cmd_write           = 3'b100,
           cmd_burst_terminate = 3'b110,
           cmd_precharge       = 3'b010,
           cmd_auto_refresh    = 3'b001,
           cmd_load_mode_reg   = 3'b000;


localparam mode_register = {
  2'b0,        // M10-11 - Reserved
  1'b1,        // M9     - No burst mode, Single access
  2'b0,        // M8-7   - Standard operation
  CAS_LATENCY, // M6-4   - CAS Latency 
  1'b0,        // M3     - Burst type
  3'b0         // M2-0   - Burst length
};


reg [3:0] refresh_timer;
reg [1:0] refresh_request;
reg refreshing;

wire refreshreset = !refreshing & RESET_n;

// Refresh roughly every 7.1uS / 8192 refreshes in 58ms
always @(posedge ECLK or negedge refreshreset) begin
  if (!refreshreset) begin
    refresh_timer <= 4'h4;
  end else begin
    if (refresh_timer > 0) begin
      refresh_timer <= refresh_timer - 1;
    end
  end
end

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    refresh_request <= 0;
  end else begin
    refresh_request <= {refresh_request[0], refresh_timer == 0};
  end
end


localparam init_poweron        = 4'b0000,
           init_precharge      = init_poweron + 1,
           init_precharge_wait = init_precharge + 1,
           init_load_mode      = init_precharge_wait + 1,
           start_refresh       = init_load_mode + 1,
           refresh_wait        = start_refresh + 1,
           idle                = refresh_wait + 1,
           active              = idle + 1,
           active_wait         = active + 1,
           data_read           = active_wait + 1,
           data_write          = data_read + 1,
           data_hold           = data_write + 1,
           precharge_wait      = data_hold + 1;

(* fsm_encoding = "compact" *) reg [3:0] ram_state;

reg init_refreshed;
reg init_done;
reg [1:0] timer_tRFC;

always @(posedge CLK or negedge RESET_n) begin
  if (!RESET_n) begin
    ram_state      <= init_poweron;
    init_refreshed <= 0;
    init_done      <= 0;
    dtack          <= 0;
    CS_n           <= 1;
    CKE            <= 1;
    DQMH           <= 1;
    DQML           <= 1;
  end else begin
    case (ram_state)

      // Showtime!
      //
      init_poweron:
        begin
          `cmd(cmd_nop)
          CS_n      <= 0;
          ram_state <= init_precharge;
        end
      
      // Init precharge
      //
      init_precharge:
        begin
          `cmd(cmd_precharge)
          MADDR[10] <= 1'b1; // Precharge all banks
          ram_state <= init_precharge_wait;
        end
      
      // Init precharge wait
      //
      // Wait for precharge to complete
      init_precharge_wait:
        begin
          `cmd(cmd_nop)
          ram_state <= start_refresh;
        end

      // Load mode register
      //
      init_load_mode:
        begin
          `cmd(cmd_load_mode_reg)
          init_done   <= 1;
          MADDR[11:0] <= mode_register;
          ram_state   <= precharge_wait;
        end

      // Refresh
      //
      // Start auto-refresh
      start_refresh:
        begin
          `cmd(cmd_auto_refresh)
          timer_tRFC <= 2'b11;
          refreshing <= 1;
          CS_n       <= 0;
          ram_state  <= refresh_wait;
        end
      
      // Refresh wait
      //
      // Wait for refresh to finish
      // During RAM initialization it will refresh twice then go to load the mode register
      refresh_wait:
        begin
          `cmd(cmd_nop)
          if (timer_tRFC > 0) begin
            timer_tRFC <= timer_tRFC - 1;
            ram_state  <= refresh_wait;
          end else begin
            if (!init_done) begin
              if (init_refreshed) begin
                // If we just finished the second init refresh go load the mode register
                ram_state      <= init_load_mode;
              end else begin
                // Do a second init refresh
                ram_state      <= start_refresh;
                init_refreshed <= 1;
              end
            end else begin
              ram_state <= idle;
            end
          end
        end

      // Idle
      //
      // Refresh has priority over memory access
      idle:
        begin
          `cmd(cmd_nop)
          refreshing <= 0;
          DQMH  <= 1;
          DQML  <= 1;
          CS_n  <= 1;
          if (refresh_request[1]) begin
            ram_state <= start_refresh;
          end else if (RAM_CYCLE && (z2_state == Z2_START || z2_state == Z2_DATA)) begin
            dtack <= 1;
            ram_state <= active;
          end else begin
            ram_state <= idle;
          end
        end

      // Active
      //
      // Activate the row/bank
      active:
        begin
          `cmd(cmd_active)
          ram_state   <= active_wait;
          MADDR[11:0] <= ADDR[21:10];
          BA[1:0]     <= ADDR[23:22];
          CS_n        <= 0;
        end

      // Wait
      //
      // Wait for tRCD and also wait until we see data strobes before committing writes
      active_wait:
        begin
          `cmd(cmd_nop)
          if (z2_state >= Z2_DATA) begin
            if (RW)
              ram_state <= data_read;
            else
              ram_state <= data_write;
          end else begin
            ram_state <= active_wait;
          end
        end

      // Read
      //
      data_read:
        begin
          `cmd(cmd_read)
          MADDR[11:0] <= {4'b010,ADDR[9:1]};
          DQMH      <= 0;
          DQML      <= 0;
          ram_state <= data_hold;
        end

      // Write
      //
      // Commit the write then go back to idle state
      data_write:
        begin
          `cmd(cmd_write)
          MADDR[11:0] <= {4'b010,ADDR[9:1]};
          DQMH        <= UDS_n;
          DQML        <= LDS_n;
          ram_state   <= precharge_wait;
        end

      // Hold
      //
      // On read cycles, take CKE low until the end of the Zorro cycle in order to hold the output
      data_hold:
        begin
          `cmd(cmd_nop)
          if (z2_state != Z2_IDLE) begin
            CKE      <= 0;
            ram_state <= data_hold;
          end else begin
            CKE       <= 1;
            ram_state <= precharge_wait;
          end
        end

      // Wait for auto-precharge to complete
      precharge_wait:
        begin
          `cmd(cmd_nop)
          dtack     <= 0;
          ram_state <= idle;
        end
    endcase
  end
end
endmodule
