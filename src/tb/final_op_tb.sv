`timescale 1ns / 1ps

module final_op_tb;

parameter LOGK       = 2 ;
parameter LOGQ       = 64;
parameter LOGQH      = 48;
parameter LOGTP      = 5 ;
parameter CORRECT    = 1 ;
parameter FF_IN      = 1 ;
parameter FF_MUL     = 1 ;
parameter FF_SUM     = 0 ;
parameter FF_SUB     = 0 ;
parameter FF_ADDSUB  = 0 ;
parameter USE_CSA    = 1 ;
parameter FF_CSA     = 1 ;
parameter MORE_DSP   = 1 ;
parameter NON_STD    = 0 ;

localparam TP = 1 << LOGTP;

reg              clk       ;
reg              rst       ;
reg              i_valid   ;
reg              o_valid   ;
reg              last      ;
reg              load_q    ;
reg [LOGQH -1:0] qH        ;
reg [LOGQ  -1:0] q_inv     ;
reg [LOGQ  -1:0] halfmod   ;
reg [LOGQ  -1:0] A [0:TP-1];
reg [LOGQ  -1:0] B [0:TP-1];
reg [LOGQ  -1:0] C [0:TP-1];

localparam HP = 5;   
localparam FP = 2 * HP; 

final_op #(
    .LOGK(LOGK),
    .LOGQ(LOGQ),
    .LOGQH(LOGQH),
    .LOGTP(LOGTP),
    .CORRECT(CORRECT),
    .FF_IN(FF_IN),
    .FF_MUL(FF_MUL),
    .FF_SUM(FF_SUM),
    .FF_SUB(FF_SUB),
    .FF_ADDSUB(FF_ADDSUB),
    .USE_CSA(USE_CSA),
    .FF_CSA(FF_CSA),
    .MORE_DSP(MORE_DSP),
    .NON_STD(NON_STD)
) final_op_inst (
    .clk(clk), 
    .rst(rst),
    .i_valid(i_valid), 
    .last(last),
    .load_q(load_q),
    .qH(qH), 
    .q_inv(q_inv),
    .halfmod(halfmod),
    .A(A), 
    .B(B), 
    .o_valid(o_valid),
    .C(C)
);

always #HP clk = ~clk;

integer i;

reg [LOGQ-1:0] memA [0:(8*TP)-1];
reg [LOGQ-1:0] memB [0:(8*TP)-1];

initial begin
    // Initialize regs
    clk = 0;
    rst = 1;
    i_valid = 0;
    o_valid = 0;
    last = 0;
    load_q = 0;

    #(1*FP);

    rst = 0;

    #(1*FP);
    #(1*HP);
    #0.1;

    // Read from files
    $readmemh("/home/berenaydogan/Documents/Relin-FPGA/src/relin/test_files/A_hex.txt", memA);
    $readmemh("/home/berenaydogan/Documents/Relin-FPGA/src/relin/test_files/B_hex.txt", memB);

    qH = 48'h800011800000;
    halfmod = 64'h400008C000000000;

    i_valid = 0;
    last = 0;
    load_q = 1;

    #(1*FP);

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[i];
        B[i] = memB[i];
    end

    i_valid = 1;
    last = 1;
    load_q = 0;

    #(1*FP);

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[1*TP + i];
        B[i] = memB[1*TP + i];
    end

    i_valid = 1;
    last = 1;
    load_q = 0;

    #(1*FP);


    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[2*TP + i];
        B[i] = memB[2*TP + i];
    end

    i_valid = 1;
    last = 1;
    load_q = 0;

    #(1*FP);

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[3*TP + i];
        B[i] = memB[3*TP + i];
    end

    i_valid = 1;
    last = 1;
    load_q = 0;

    #(1*FP);

    i_valid = 0;
    last = 0;
    load_q = 0;

    #(3*FP);

    qH = 48'h800000000008;
    halfmod = 64'h4000000000040000;
    q_inv = 64'h6d7e851bb730f6bc;

    i_valid = 0;
    last = 0;
    load_q = 1;

    #(1*FP);

    qH = 48'h80000000004A;
    halfmod = 64'h4000000000250000;
    q_inv = 64'h120c1aa6b5e7e586;

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[4*TP+i];
        B[i] = memB[4*TP+i];
    end

    i_valid = 1;
    last = 0;
    load_q = 1;

    #(1*FP);

    qH = 48'h80000000005E;
    halfmod = 64'h40000000002f0000;
    q_inv = 64'h276231a3ae9b8c78;

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[5*TP + i];
        B[i] = memB[5*TP + i];
    end

    i_valid = 1;
    last = 0;
    load_q = 1;

    #(1*FP);

    qH = 48'h80000000007a;
    halfmod = 64'h40000000003d0000;
    q_inv = 64'h3cb7e4ed1da84928;

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[6*TP + i];
        B[i] = memB[6*TP + i];
    end

    i_valid = 1;
    last = 0;
    load_q = 1;

    #(1*FP);

    for (i = 0; i < TP; i = i + 1) begin
        A[i] = memA[7*TP + i];
        B[i] = memB[7*TP + i];
    end

    i_valid = 1;
    last = 0;
    load_q = 0;

    #(1*FP);

    i_valid = 0;
    last = 0;
    load_q = 0;

    #(25*FP);


    $finish;
end

endmodule
