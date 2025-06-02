`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2022 04:49:27 PM
// Design Name: 
// Module Name: parameters
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1 ns / 1 ps

// ------------------------------------------------
// User parameters
// -- K: DATA_SIZE_ARB
// -- n: RING_SIZE
// -- B: PE_NUMBER

`define STAGE_SIZE      6
`define RING_SIZE       64
`define RING_DEPTH       ($clog2(`RING_SIZE))
`define BUTTERFLY_SIZE  `RING_SIZE>>1
`define MODULUS_WIDTH   96
`define GOLD_MODULUS_WIDTH 64

`define STREAM_SIZE 32
`define STREAM_ADDR_WIDTH  ($clog2(`STREAM_SIZE))
`define STREAM_COUNTER_SIZE `RING_SIZE*`RING_SIZE*`GOLD_MODULUS_WIDTH>>`STREAM_ADDR_WIDTH
`define COUNTER_WIDTH ($clog2(`STREAM_COUNTER_SIZE))+1
`define ADDR_WIDTH ($clog2(`GOLD_MODULUS_WIDTH))

`define BUTTER_FLY_REGISTERS 4
`define BRAM_SIZE 2*`RING_SIZE

`define MULTIPLIER_LATENCY 18
`define REDUCTION_LATENCY 4