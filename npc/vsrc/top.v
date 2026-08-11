// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2017 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// See also https://verilator.org/guide/latest/examples.html"
module top(
  input clk,
  input rst,
  input a,
  input b,
  output f
);
  assign f = a ^ b;
endmodule
