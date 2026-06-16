// Generic FIFO.
// Author: Carlos Diaz (2017)
//
// DISCLAIMER (2021): This implementation was done when I had a few days of
// experience using verilog, I was at school and not really sure what
// I was doing. I choose to make it public in case of me needing it
// in the future, but that was not the case, it's been a long time
// since I tried to learn any HDL.
//
// Parameters:
//  WIDTH: Width of the data on the FIFO, default to 4.
//  DEPTH: Depth of the FIFO, default to 4.
//
// Input signals:
//  data_in: Data input, width controlled with WIDTH parameter.
//  clk: Clock input.
//  write: Enable writing into the FIFO.
//  read: Enable reading from the FIFO.
//
// Output signals:
//  data_out: Data output, witdh controlled with WIDTH parameter.
//  fifo_full: 1bit signal, indicate when the FIFO is full.
//  fifo_empty: 1bit signal, indicate when the FIFO is empty.
//  fifo_not_empty: 1bit signal, indicate when the FIFO is not empty.
//  fifo_not_full: 1bit signal, indicate when the FIFO is not full.

`timescale 1ns / 1ps

interface fifo_intf #(parameter WIDTH = 4);
  logic [WIDTH-1:0] data_in    ;
  logic             write      ;
  logic             read       ;
  logic [WIDTH-1:0] data_out   ;
  logic             fifo_full  ;
  logic             fifo_empty ;
endinterface

module fifo #(
    parameter WIDTH = 4,
    parameter DEPTH = 4
  )(
    input     clk,
    fifo_intf intf
  );

  localparam PTR_MSB  = $clog2(DEPTH);
  localparam ADDR_MSB = PTR_MSB - 1;

  // memory will contain the FIFO data.
  reg  [WIDTH-1:0] memory [0:DEPTH-1];

  // $clog2(DEPTH+1)-2 to count from 0 to DEPTH
  reg  [PTR_MSB:0] write_ptr = 0;
  reg  [PTR_MSB:0] read_ptr  = 0;

  wire [ADDR_MSB:0] write_addr = write_ptr[ADDR_MSB:0];
  wire [ADDR_MSB:0] read_addr  = read_ptr [ADDR_MSB:0];

  always @ (posedge clk)
    if (intf.write) begin
      memory[write_addr] <= intf.data_in;
      write_ptr <= write_ptr + 1;
    end

  always @ (posedge clk)
    if (intf.read & ~intf.fifo_empty) begin
      read_ptr <= read_ptr + 1;
    end

  assign intf.data_out = memory[read_addr];

  assign intf.fifo_empty = (write_ptr == read_ptr);
  assign intf.fifo_full  = (write_ptr[ADDR_MSB:0] == read_ptr[ADDR_MSB:0]) & 
                           (write_ptr[PTR_MSB]    != read_ptr[PTR_MSB]   ) ;

endmodule