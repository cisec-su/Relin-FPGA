`include "modadd.svh"
`include "modsub.svh"
`include "modmul_wlm.svh"
`include "wlm.svh"

module final_op
   #(   
        parameter LOGK       = 10,
        parameter LOGQ       = 64,
        parameter LOGQH      = 17,
        parameter LOGN       = 16,
        parameter LOGTP      = 5 ,
        parameter W          = 64,
        parameter CORRECT    = 1 ,
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
        input               clk       ,
        input               rst       ,
        input               last      ,
        input               load_q    ,
        input  [LOGQH -1:0] qH        ,
        input  [LOGQ  -1:0] q_inv     ,
        input  [LOGQ  -1:0] half      ,
        input  [LOGQ  -1:0] halfmod   ,
        input  [W     -1:0] A [0:TP-1],
        input  [LOGQ  -1:0] B [0:TP-1],
        output [W     -1:0] C [0:TP-1]
    );

///////////////////////////// Parameters ////////////////////////////////

localparam K = (1 << LOGK);

localparam modadd_params_t modadd_last_params = {W, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_ADD_LAST = modadd_lat(modadd_last_params);

localparam modadd_params_t modadd_params = {W, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_ADD = modadd_lat(modadd_params);

localparam modsub_params_t modsub_halfmod_params = {W, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_SUB_HALFMOD = modsub_lat(modsub_halfmod_params);

localparam modsub_params_t modsub_params = {W, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_SUB = modsub_lat(modsub_params);

localparam modmul_wlm_params_t modmul_params = {W, LOGQ, LOGQH, 1, 0, FF_MUL, FF_SUM, FF_SUB, 1, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
localparam LAT_MUL = modmul_wlm_lat(modmul_params);

localparam LAT = (last) ? (LAT_ADD_LAST) : (LAT_SUB_HALFMOD + LAT_SUB + LAT_MUL + LAT_ADD);

localparam TP = 1 << LOGTP;

/////////////////////////////////////////////////////////////////////////

///////////////////////// Type Declarations /////////////////////////////

typedef enum logic [4:0] {
    ST_IDLE              = 5'b00001,
    ST_READ              = 5'b00010,
    ST_WRITE_INIT        = 5'b00100,
    ST_WRITE_LOOP        = 5'b01000,
    ST_WRITE_END         = 5'b10000
} state_t;

/////////////////////////////////////////////////////////////////////////

///////////////////////// Signal Declarations ///////////////////////////

reg [LOGQH-1:0] qH_int;
reg [LOGQ-1:0] q_inv_int;
reg [LOGQ-1:0] half_int;
reg [LOGQ-1:0] halfmod_int;
reg [LOGQ-1:0] poly_last [0:TP-1];

reg [W   -1:0] A_q [0:TP-1];
reg [LOGQ-1:0] B_q [0:TP-1];

wire [LOGQ-1:0] modsub_halfmod_result [0:TP-1];
wire [LOGQ-1:0] modsub_result [0:TP-1];
wire [LOGQ-1:0] modmul_wlm_result [0:TP-1];

wire [LOGQ-1:0] modsub_halfmod_out [0:TP-1];
wire [LOGQ-1:0] modsub_out [0:TP-1];
wire [LOGQ-1:0] modmul_wlm_out [0:TP-1];
wire [LOGQ-1:0] modadd_out [0:TP-1];

wire [LOGQ-1 :0] bram_out [TP-1:0]; 

reg [LOGK-1:0] read_addr;
reg [LOGK-1:0] write_addr;
reg start_read, start_write;

reg bram_wen;

state_t state, next_state;

/////////////////////////////////////////////////////////////////////////

generate
    for (genvar i = 0; i < TP; i++) begin : OUT_GEN
        assign C[i] = bram_out[i];
    end
endgenerate

/////////////////////////////////////////////////////////////////////////

generate
    genvar i;
    for (i = 0; i < TP; i = i + 1) begin
        if (last) begin
            modadd #(
                .LOGA(W),
                .LOGB(LOGQ),
                .LOGQ(LOGQ),
                .LOGQH(LOGQH),
                .FF_IN(1),
                .FF_ADD(FF_ADDSUB),
                .FF_OUT(1)
            ) modadd_inst (
                .clk(clk),
                .A(A_q[i]),
                .B(half_int),
                .qH(qH_int),
                .C(modadd_out[i])
            );
        end else begin
            modsub #(
                .LOGA(LOGQ),
                .LOGB(LOGQ),
                .LOGQ(LOGQ),
                .LOGQH(LOGQH),
                .FF_IN(1),
                .FF_SUB(FF_ADDSUB),
                .FF_OUT(1)
            ) modsub_halfmod_inst (
                .clk(clk),
                .A(poly_last[i]),
                .B(halfmod_int),
                .qH(qH_int),
                .C(modsub_halfmod_result[i])
            );

            shift_reg_arr #(
                .SHIFT  (LAT_SUB),
                .WIDTH  (LOGQ),
                .LENGTH (TP)
            ) shift_modsub_halfmod (
                .clk   (clk),
                .rst   (rst),
                .i_data(modsub_halfmod_result),
                .o_data(modsub_halfmod_out)
            );

            modsub #(
                .LOGA(W),
                .LOGB(LOGQ),
                .LOGQ(LOGQ),
                .LOGQH(LOGQH),
                .FF_IN(0),
                .FF_SUB(FF_ADDSUB),
                .FF_OUT(1)
            ) modsub_inst (
                .clk(clk),
                .A(A_q[i]),
                .B(modsub_halfmod_out[i]),
                .qH(qH_int),
                .C(modsub_result[i])
            );

            shift_reg_arr #(
                .SHIFT  (LAT_SUB),
                .WIDTH  (LOGQ),
                .LENGTH (TP)
            ) shift_modsub (
                .clk   (clk),
                .rst   (rst),
                .i_data(modsub_result),
                .o_data(modsub_out)
            );

            modmul_wlm #(
                .LOGQ(LOGQ),
                .LOGQH(LOGQH),
                .CORRECT(CORRECT),
                .FF_IN(0),
                .FF_MUL(FF_MUL),
                .FF_SUM(FF_SUM),
                .FF_SUB(FF_SUB),
                .FF_OUT(1),
                .USE_CSA(USE_CSA),
                .FF_CSA (FF_CSA),
                .MORE_DSP(MORE_DSP),
                .NON_STD(NON_STD)
            ) modmul_wlm_inst (
                .clk(clk),
                .A(modsub_out[i]),
                .B(q_inv_int),
                .qH(qH_int),
                .T(modmul_wlm_result[i])
            );

            shift_reg_arr #(
                .SHIFT  (LAT_MUL),
                .WIDTH  (LOGQ),
                .LENGTH (TP)
            ) shift_modmul_wlm (
                .clk   (clk),
                .rst   (rst),
                .i_data(modmul_wlm_result),
                .o_data(modmul_wlm_out)
            );

            modadd #(
                .LOGA(LOGQ),
                .LOGB(LOGQ),
                .LOGQ(LOGQ),
                .LOGQH(LOGQH),
                .FF_IN(0),
                .FF_ADD(FF_ADDSUB),
                .FF_OUT(1)
            ) modadd_inst (
                .clk(clk),
                .A(modmul_wlm_out[i]),
                .B(B_q[i]),
                .qH(qH_int),
                .C(modadd_out[i])
            );
        end
    end
endgenerate

/////////////////////////////////////////////////////////////////////////

generate
    for (genvar i = 0; i < TP; i++) begin : BRAM_GEN
        bram #(
            .WIDTH (LOGQ),
            .LENGTH(K   )
        ) bram_inst (
            .clk  (clk          ),
            .wen  (bram_wen     ),
            .waddr(write_addr   ),
            .din  (modadd_out[i]),
            .raddr(read_addr    ),
            .dout (bram_out[i]  )
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////

always @(posedge clk) begin
    if (rst) begin
        qH_int <= 0;
        q_inv_int <= 0;
        half_int <= 0;
        halfmod_int <= 0;
        for (integer j = 0; j < TP; j = j + 1) begin
            poly_last[j] <= 0;
        end
    end else if (load_q) begin
        qH_int <= qH;
        q_inv_int <= q_inv;
        halfmod_int <= halfmod;
    end else if (last) begin
        half_int <= half;
        for (integer j = 0; j < TP; j = j + 1) begin
            poly_last[j] <= bram_out[j];
        end
    end
end 

always @(posedge clk) begin
    for (integer i = 0; i < TP; i = i + 1) begin
        A_q[i] <= A[i];
        B_q[i] <= B[i];
    end
end

counter #(
    .WIDTH(LOGK)
) ctr_write_inst (
    .clk   (clk        ),
    .rst   (rst        ),
    .inc   (start_write),
    .ctr   (write_addr )
);

always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state  = state; 
    o_valid     = 0;
    done        = 0;
    busy        = 0;
    bram_wen    = 0;
    start_write = 0;
    start_read  = 0;
    case (state)
        ST_IDLE: begin
            if (ren) begin
                start_read = 1;
                next_state = ST_READ;
            end else if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
        end
        ST_READ: begin
            busy = 1;
            if (read_addr == 1) begin
                o_valid = 1;
            end
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_IDLE;
            end
        end
        ST_WRITE_INIT: begin
            busy = 1;
            if (read_addr == LAT) begin
                start_write = 1;
                next_state  = ST_WRITE_LOOP;
            end
        end
        ST_WRITE_LOOP: begin
            busy = 1;
            bram_wen = 1;
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_WRITE_END;
            end
        end
        ST_WRITE_END: begin
            bram_wen  = 1;
            if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
            else if (write_addr == (K - 1)) begin
                next_state = ST_IDLE;
            end
        end
        default: next_state = ST_IDLE;
    endcase
end

endmodule
