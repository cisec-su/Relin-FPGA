`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: hadamart_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for the hadamart module
// 
// Dependencies: hadamart.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module hadamart_tb;

localparam W = 64; 
localparam TP = 32;
localparam HP = 5;
localparam FP = 2 * HP;

reg clk;
reg rst;

reg [W-1:0] q;
reg [W-1:0] A [TP-1:0];
reg [W-1:0] B [TP-1:0];

wire [W-1:0] C [TP-1:0];

hadamart #(
    .W(W),
    .TP(TP)
) dut (
    .clk(clk),
    .rst(rst),
    .q(q),
    .A(A),
    .B(B),
    .C(C)
);

always #HP clk = ~clk;

integer i;

initial begin
    $display("Starting simulation.");

    clk = 1'b0;
    rst = 1'b0;
    #FP;
    rst = 1'b1;
    #FP;
    rst = 1'b0;
    #(HP);
    
    // Test case 1
    q = 64'h8000118000000001;
    for (i = 0; i < TP; i = i + 1) begin
        A[i] = i+1;
        B[i] = (i + 1) * 2;
    end    
    
    #(FP * 100); 

    for (i = 0; i < TP; i = i + 1) begin
        $display("Test Case 1 -> A[%0d] = %x, B[%0d] = %x, C[%0d] = %x", i, A[i], i, B[i], i, C[i]);
    end

    // Test case 2
    for (i = 0; i < TP; i = i + 1) begin
        A[i] = (i + 3) * 5;
        B[i] = (i + 2) * 7;
    end  

    #(FP * 100); 

    for (i = 0; i < TP; i = i + 1) begin
        $display("Test Case 2 -> A[%0d] = %x, B[%0d] = %x, C[%0d] = %x", i, A[i], i, B[i], i, C[i]);
    end
    
    $finish;
end

endmodule
