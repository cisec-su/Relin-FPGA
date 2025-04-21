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

localparam K = 1 << LOGK;

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

localparam LAT_LAST = final_op_inst.LAT_LAST;
localparam LAT = final_op_inst.LAT;

always #HP clk = ~clk;

integer i;
integer j;

reg [LOGQ-1:0] memA [0:(32*TP)-1];
reg [LOGQ-1:0] memB [0:(36*TP)-1];

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
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/A_hex_new.txt", memA);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/B_hex_new.txt", memB);

    qH = 48'h800011800000;
    halfmod = 64'h400008C000000000;

    i_valid = 0;
    last = 0;
    load_q = 1;

    #(1*FP);

    i_valid = 1;
    last = 1;
    load_q = 0;

    for (j = 0; j < K; j = j + 1) begin
        for (i = 0; i < TP; i = i + 1) begin
            A[i] = memA[(j*TP)+i];
        end
        #(1*FP);
        i_valid = 0;
        last = 0;
        load_q = 0;
    end

    #((LAT_LAST-1)*FP);

    qH = 48'h800000000008;
    halfmod = 64'h4000000000040000;
    q_inv = 64'h6d7e851bb730f6bc;

    i_valid = 0;
    last = 0;
    load_q = 1;

    #(1*FP);

    i_valid = 1;
    last = 0;
    load_q = 0;

    for (j = K; j < 2*K; j = j + 1) begin
        for (i = 0; i < TP; i = i + 1) begin
            A[i] = memA[(j*TP)+i];
            B[i] = memB[((j-K)*TP)+i];
        end
        #(1*FP);
        i_valid = 0;
        last = 0;
        load_q = 0;
    end

    i_valid = 1;
    last = 0;
    load_q = 0;

    for (j = 2*K; j < 3*K; j = j + 1) begin
        for (i = 0; i < TP; i = i + 1) begin
            A[i] = memA[(j*TP)+i];
            B[i] = memB[((j-K)*TP)+i];
        end
        #(1*FP);
        i_valid = 0;
        last = 0;
        load_q = 0;
    end

    #((LAT-1)*FP);

    i_valid = 0;
    last = 0;
    load_q = 1;

    qH = 48'h80000000004A;
    halfmod = 64'h4000000000250000;
    q_inv = 64'h120c1aa6b5e7e586;

    #(1*FP);

    i_valid = 1;
    last = 0;
    load_q = 0;

    for (j = 3*K; j < 4*K; j = j + 1) begin
        for (i = 0; i < TP; i = i + 1) begin
            A[i] = memA[(j*TP)+i];
            B[i] = memB[((j-K)*TP)+i];
        end
        #(1*FP);
        i_valid = 0;
        last = 0;
        load_q = 0;
    end

    i_valid = 1;
    last = 0;
    load_q = 0;

    for (j = 4*K; j < 5*K; j = j + 1) begin
        for (i = 0; i < TP; i = i + 1) begin
            A[i] = memA[(j*TP)+i];
            B[i] = memB[((j-K)*TP)+i];
        end
        #(1*FP);
        i_valid = 0;
        last = 0;
        load_q = 0;
    end

    #(LAT*FP);
    #(5*FP);


    $finish;
end

endmodule
