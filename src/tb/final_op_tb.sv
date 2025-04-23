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
localparam B_SHIFT = final_op_inst.B_SHIFT;

integer exp_idx = 0;
integer mismatch_cnt = 0;

reg run_flag = 0;
integer run_ctr = 0;

integer i;
integer j;
integer s;
integer r;
integer v;
integer sA;
integer jA;
integer sB;
integer jB;
integer B_idx;
integer full_set;

localparam set_count = 4;
localparam set_size = 2;
localparam last_count = 1;
localparam last_size = 1;

reg [LOGQ -1:0] memA [0:((set_count * set_size + last_count * last_size) * K * TP)-1];
reg [LOGQ -1:0] memB [0:((set_count * set_size) * K * TP)-1];
reg [LOGQH-1:0] memqH [0:(set_count + last_count - 1)];
reg [LOGQ -1:0] memhalfmod [0:(set_count + last_count - 1)];
reg [LOGQ -1:0] memq_inv [0:(set_count - 1)];
reg [LOGQ -1:0] memexp [0:((set_count * set_size + last_count * last_size) * K * TP)-1];

always #HP clk = ~clk;

initial begin
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/A.txt", memA);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/B.txt", memB);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/qH.txt", memqH);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/halfmod.txt", memhalfmod);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/q_inv.txt", memq_inv);
    $readmemh("/home/berenaydogan/SU_Project/Relin-FPGA/src/test_files/C.txt", memexp);
end

always @(posedge clk) begin
    if (rst) begin
        run_flag <= 0;
        run_ctr <= 0;
    end else begin
        if (o_valid && !run_flag) begin
            run_flag <= 1;
            run_ctr <= 0;
        end
        if (o_valid || run_flag) begin
            for (v = 0; v < TP; v = v + 1) begin
                if (C[v] !== memexp[exp_idx]) begin
                    $display("Test Failed -> word %0d  got=%h  exp=%h", exp_idx, C[v], memexp[exp_idx]);
                    mismatch_cnt = mismatch_cnt + 1;
                end else begin
                    $display("Test Passed -> word %0d  got=%h  exp=%h", exp_idx, C[v], memexp[exp_idx]);
                end
                exp_idx = exp_idx + 1;
            end
            run_ctr = run_ctr + 1;
            if (run_ctr == K - 1) begin
                run_flag <= 0;
            end
        end
        if (exp_idx == (set_count * set_size + last_count * last_size) * K * TP) begin
            if (mismatch_cnt == 0)
                $display("\nAll tests passed.\n");
            else
                $display("\nThere were %0d mismatches in the results.\n", mismatch_cnt);
            #(5*FP);
            $finish;
        end
    end
end

initial begin
    $display("Starting simulation.");
    clk = 0;
    rst = 1;
    i_valid = 0;
    last = 0;
    load_q = 0;

    #(1*FP);

    rst = 0;

    #(1*FP);
    #(1*HP);
    #0.1;

    for (r = 0; r < last_count; r = r + 1) begin

        qH = memqH[r];
        halfmod = memhalfmod[r];

        i_valid = 0;
        last = 0;
        load_q = 1;

        #(1*FP);

        for (s = 0; s < last_size; s = s + 1) begin

            i_valid = 1;
            last = 1;
            load_q = 0;

            for (j = 0; j < K; j = j + 1) begin

                for (i = 0; i < TP; i = i + 1) begin
                    A[i] = memA[((s + j) * TP) + i];
                end

                #(1*FP);

                i_valid = 0;
                last = 0;
                load_q = 0;

            end
        end

        #((LAT_LAST - 1) * FP);

    end

    for (r = 0; r < set_count; r = r + 1) begin

        qH = memqH[r + last_count];
        halfmod = memhalfmod[r + last_count];
        q_inv = memq_inv[r];

        i_valid = 0;
        last = 0;
        load_q = 1;

        #(1*FP);

        full_set = set_size * K;

        for (s = 0; s < full_set + B_SHIFT; s = s + 1) begin
            if (s < full_set) begin

                sA = s / K;
                jA = s % K;

                for (i = 0; i < TP; i = i + 1) begin
                    A[i] = memA[(((((set_size * r) + sA) + (last_count * last_size)) * K + jA) * TP) + i];
                end

                i_valid = (jA == 0);
                last = 0;
                load_q = 0;

            end 
            else begin

                i_valid = 0;
                last = 0;
                load_q = 0;

            end

            B_idx = s + 1 - B_SHIFT;

            if (B_idx >= 0 && B_idx < full_set) begin

                sB = B_idx / K;
                jB = B_idx % K;

                for (i = 0; i < TP; i = i + 1) begin
                    B[i] = memB[(((set_size * r) + sB) * K + jB) * TP + i];
                end

            end

            #(1*FP);

        end

        #((LAT - B_SHIFT) * FP);

    end

    #(5*FP);

    $finish;
end

endmodule
