`include "modadd.svh"
`include "modsub.svh"
`include "modmul_wlm.svh"
`include "wlm.svh"

module final_op
   #(   
        parameter LOGK       = 10,
        parameter LOGQ       = 64,
        parameter LOGQH      = 47,
        parameter LOGTP      = 5 ,
        parameter CORRECT    = 1 ,
        parameter FF_IN      = 1 ,
        parameter FF_MUL     = 1 ,
        parameter FF_SUM     = 0 ,
        parameter FF_SUB     = 0 ,
        parameter FF_ADDSUB  = 0 ,
        parameter USE_CSA    = 1 ,
        parameter FF_CSA     = 1 ,
        parameter MORE_DSP   = 1 ,
        parameter NON_STD    = 0
    )
    (
        input                   clk       ,
        input                   rst       ,
        input                   i_valid   ,
        input                   o_valid   ,
        input                   last      ,
        input                   load_q    ,
        input      [LOGQH -1:0] qH        ,
        input      [LOGQ  -1:0] q_inv     ,
        input      [LOGQ  -1:0] half      ,
        input      [LOGQ  -1:0] halfmod   ,
        input      [LOGQ  -1:0] A [0:TP-1],
        input      [LOGQ  -1:0] B [0:TP-1],
        output reg [LOGQ  -1:0] C [0:TP-1]
    );

///////////////////////////// Parameters ////////////////////////////////

localparam modadd_params_t modadd_params_last = {LOGQ, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_ADD_LAST = modadd_lat(modadd_params_last);

localparam modadd_params_t modadd_params = {LOGQ, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_ADD = modadd_lat(modadd_params);

localparam modsub_params_t modsub0_params = {LOGQ, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_SUB0 = modsub_lat(modsub0_params);

localparam modsub_params_t modsub1_params = {LOGQ, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_SUB1 = modsub_lat(modsub1_params);

localparam modmul_wlm_params_t modmul_params = {LOGQ, LOGQ, LOGQH, CORRECT, 0, FF_MUL, FF_SUM, FF_SUB, 1, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
localparam LAT_MUL = modmul_wlm_lat(modmul_params);

localparam LAT_LAST = LAT_ADD_LAST + 2;
localparam LAT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + LAT_ADD_LAST + 7;

localparam K  = 1 << LOGK;
localparam TP = 1 << LOGTP;

localparam A_SHIFT = LAT_SUB0;
localparam B_SHIFT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + 6;

/////////////////////////////////////////////////////////////////////////

///////////////////////// Signal Declarations ///////////////////////////

reg  [LOGQH-1:0] qH_q;
reg  [LOGQ -1:0] q_inv_q;
reg  [LOGQ -1:0] half_q;
reg  [LOGQ -1:0] halfmod_q;

reg last_q;

reg  [LOGQ -1:0] A_reg [0:TP-1];
reg  [LOGQ -1:0] B_reg [0:TP-1];
reg  [LOGQ -1:0] A_q [0:TP-1];
reg  [LOGQ -1:0] B_q [0:TP-1];

reg  [LOGQ -1:0] A_int1 [0:TP-1];
reg  [LOGQ -1:0] A_int2 [0:TP-1];

reg [LOGQ-1:0] C_q [0:TP-1];

reg wen;

wire A_shift;
wire B_shift;

wire [LOGQ -1:0] modadd_in_A  [0:TP-1];
wire [LOGQ -1:0] modadd_in_B  [0:TP-1];
wire [LOGQ -1:0] modadd_out   [0:TP-1];

wire [LOGQ -1:0] modsub0_in_A [0:TP-1];
wire [LOGQ -1:0] modsub0_in_B [0:TP-1];
wire [LOGQ -1:0] modsub0_out  [0:TP-1];

wire [LOGQ -1:0] modsub1_in_A [0:TP-1];
wire [LOGQ -1:0] modsub1_in_B [0:TP-1];
wire [LOGQ -1:0] modsub1_out  [0:TP-1];

wire [LOGQ -1:0] modmul_in_A  [0:TP-1];
wire [LOGQ -1:0] modmul_in_B  [0:TP-1];
wire [LOGQ -1:0] modmul_out   [0:TP-1];

wire [LOGQ -1:0] bram_in      [0:TP-1];
wire [LOGQ -1:0] bram_out     [0:TP-1]; 

reg  [LOGK -1:0] read_addr;
reg  [LOGK -1:0] write_addr;

/////////////////////////////////////////////////////////////////////////



//////////////////////// Input Registering //////////////////////////////

shift_reg #(
    .SHIFT (LAT_LAST),
    .WIDTH (1),
    .RST_EN(0)
) shift_reg_wen (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (wen  ),
    .o_data (wen_q)
);

shift_reg_arr #(
    .SHIFT (1   ),
    .WIDTH (LOGQ),
    .LENGTH(TP  ),
    .RST_EN(0   )
) shift_reg_A1 (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (A_reg ),
    .o_data (A_int1)
);

shift_reg_arr #(
    .SHIFT (A_SHIFT - 1),
    .WIDTH (LOGQ       ),
    .LENGTH(TP         ),
    .RST_EN(0          )
) shift_reg_A2 (
    .clk    (clk  ),
    .rst    (rst  ),
    .i_data (A_int1),
    .o_data (A_int2)
);

shift_reg_arr #(
    .SHIFT (B_SHIFT),
    .WIDTH (LOGQ   ),
    .LENGTH(TP     ),
    .RST_EN(0      )
) shift_reg_B (
    .clk    (clk  ),
    .rst    (rst  ),
    .i_data (B_reg),
    .o_data (B_q  )
);


/////////////////////////////////////////////////////////////////////////



////////////////////// Combinational Assignments ////////////////////////

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign modadd_in_A[i] = (last_q) ? A_q[i] : modmul_out[i];
        assign modadd_in_B[i] = (last_q) ? half_q : B_q[i];
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign bram_in[i] = modadd_out[i];
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign modsub0_in_A[i] = bram_out[i];
        assign modsub0_in_B[i] = halfmod_q;
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign modsub1_in_A[i] = A_q[i];
        assign modsub1_in_B[i] = modsub0_out[i];
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign modmul_in_A[i] = modsub1_out[i];
        assign modmul_in_B[i] = q_inv_q;
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i++) begin
        assign C_q[i] = modadd_out[i];
    end
endgenerate


/////////////////////////////////////////////////////////////////////////



////////////////////////////// Final Op /////////////////////////////////

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign A_q[i] = (last_q) ? A_int1[i] : A_int2[i];
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        modadd #(
            .LOGA  (LOGQ     ),
            .LOGB  (LOGQ     ),
            .LOGQ  (LOGQ     ),
            .LOGQH (LOGQH    ),
            .FF_IN (1        ),
            .FF_ADD(FF_ADDSUB),
            .FF_OUT(1        )
        ) modadd_inst (
            .clk(clk           ),
            .A  (modadd_in_A[i]),
            .B  (modadd_in_B[i]),
            .qH (qH_q          ),
            .C  (modadd_out[i] )
        );
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        modsub #(
            .LOGA  (LOGQ     ),
            .LOGB  (LOGQ     ),
            .LOGQ  (LOGQ     ),
            .LOGQH (LOGQH    ),
            .FF_IN (1        ),
            .FF_SUB(FF_ADDSUB),
            .FF_OUT(1        )
        ) modsub_inst0 (
            .clk(clk            ),
            .A  (modsub0_in_A[i]),
            .B  (modsub0_in_B[i]),
            .qH (qH_q           ),
            .C  (modsub0_out[i] )
        );
    end
endgenerate

generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        modsub #(
            .LOGA  (LOGQ     ),
            .LOGB  (LOGQ     ),
            .LOGQ  (LOGQ     ),
            .LOGQH (LOGQH    ),
            .FF_IN (1        ),
            .FF_SUB(FF_ADDSUB),
            .FF_OUT(0        )
        ) modsub_inst1 (
            .clk(clk            ),
            .A  (modsub1_in_A[i]),
            .B  (modsub1_in_B[i]),
            .qH (qH_q           ),
            .C  (modsub1_out[i] )
        );
    end
endgenerate


generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        modmul_wlm #(
            .LOGQ    (LOGQ    ),
            .LOGQH   (LOGQH   ),
            .CORRECT (CORRECT ),
            .FF_IN   (0       ),
            .FF_MUL  (FF_MUL  ),
            .FF_SUM  (FF_SUM  ),
            .FF_SUB  (FF_SUB  ),
            .FF_OUT  (1       ),
            .USE_CSA (USE_CSA ),
            .FF_CSA  (FF_CSA  ),
            .MORE_DSP(MORE_DSP),
            .NON_STD (NON_STD )
        ) modmul_wlm_inst (
            .clk(clk           ),
            .A  (modmul_in_A[i]),
            .B  (modmul_in_B[i]),
            .qH (qH_q          ),
            .T  (modmul_out[i] )
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////



////////////////////////// BRAM Instances ///////////////////////////////

generate
    for (genvar i = 0; i < TP; i++) begin
        bram #(
            .WIDTH (LOGQ),
            .LENGTH(K   )
        ) bram_inst (
            .clk  (clk        ),
            .wen  (wen_q      ),
            .waddr(write_addr ),
            .din  (bram_in[i] ),
            .raddr(read_addr  ),
            .dout (bram_out[i])
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////



///////////////////////////// Sequential Logic //////////////////////////

always @(posedge clk) begin
    if (rst) begin
        qH_q <= 0;
        q_inv_q <= 0;
        half_q <= 0;
        halfmod_q <= 0;
    end else if (load_q) begin
        qH_q <= qH;
        q_inv_q <= q_inv;
        half_q <= half;
        halfmod_q <= halfmod;
    end
end

always @(posedge clk) begin
    if (rst) begin
        last_q <= 0;
    end
    else if (i_valid) begin
        last_q <= last;
    end
end

for (genvar i = 0; i < TP; i = i + 1) begin
    always @(posedge clk) begin
        if (rst) begin
            A_reg[i] <= 0;
        end
        else if (i_valid) begin
            A_reg[i] <= A[i];
        end
    end
end

for (genvar i = 0; i < TP; i = i + 1) begin
    always @(posedge clk) begin
        if (rst) begin
            B_reg[i] <= 0;
        end
        else if (i_valid && !last) begin
            B_reg[i] <= B[i];
        end
    end
end

always @(posedge clk) begin
    if (i_valid && last && !rst) begin
        wen <= 1;
    end
    else begin
        wen <= 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        write_addr <= -1;
    end
    else if (i_valid && last) begin
        write_addr <= write_addr + 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        read_addr <= -1;
    end
    else if (i_valid && !last_q && load_q) begin
        read_addr <= read_addr + 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < TP; i = i + 1) begin
            C[i] <= 0;
        end
    end 
    else if (o_valid) begin
        for (int i = 0; i < TP; i = i + 1) begin
            C[i] <= C_q[i];
        end
    end
end

endmodule
