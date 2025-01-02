`include "relin_if.svh"

module relin
   #(   
        parameter L        = 30  , // Number of primes
        parameter LOGQ     = 64  ,
        parameter LOGQH    = 64  ,
        parameter LOGN     = 16  ,
        parameter LOGTP    = 5  , // polyicient throughput
        parameter NT       = 1024 // Number of twiddles that must be loaded
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        output reg         done  ,
        relin_t.master     relin_t
    );


localparam LOGL = $rtoi($ceil($clog2(L)));
localparam TP = 1 << LOGTP;

typedef enum reg[10:0] {
    ST_IDLE                      = 11'b00000000001,
    ST_LOAD_Q                    = 11'b00000000010,
    ST_LOAD_PSI_START_READ       = 11'b00000000100,
    ST_LOAD_PSI_READ_UNTIL_DONE  = 11'b00000001000,
    ST_NTT_HP_ACC                = 11'b00000010000,
    ST_LOAD_IPSI_START_READ      = 11'b00000100000,
    ST_LOAD_IPSI_READ_UNTIL_DONE = 11'b00001000000,
    ST_INTT_0_START              = 11'b00010000000,
    ST_INTT_FN                   = 11'b00100000000,
    ST_WAIT_WRITE                = 11'b01000000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;

reg [LOGL-1:0] ctr_poly;
reg ctr_poly_inc;
reg ctr_poly_rst;

reg [LOGL-1:0] ctr_rlk;
reg ctr_rlk_inc;
reg ctr_rlk_rst;

reg [LOGL-1:0] ctr_acc;
reg ctr_acc_inc;
reg ctr_acc_rst;

reg [LOGL-1:0] ctr_L; // counter for L
reg ctr_L_inc;
reg ctr_L_rst;

wire [LOGQH-1:0] qH;
// fsm <-> ntt, hadamard, accumulator, final_op
reg  load_q;
// mem <-> fsm
reg i_psi_en, i_psi_inv;
wire i_psi_ready, i_psi_valid, i_psi_done;
reg [LOGL-1:0] i_psi_id;
reg i_poly_en;
wire i_poly_ready, i_poly_valid, i_poly_done;
reg [LOGL-1:0] i_poly_id;
reg i_rlk0_en;
wire i_rlk0_ready, i_rlk0_valid, i_rlk0_done;
reg [LOGL-1:0] i_rlk0_id;
reg i_rlk1_en;
wire i_rlk1_ready, i_rlk1_valid, i_rlk1_done;
reg [LOGL-1:0] i_rlk1_id;
reg o_poly_en;
wire o_poly_ready, o_poly_done;
reg  [LOGL-1:0] o_poly_id;
// mem -> ntt
wire [LOGQ-1:0] i_psi_poly [0:TP-1];
wire [LOGQ-1:0] i_poly_data [0:TP-1];
// mem -> hadamard
wire [LOGQ-1:0] i_rlk0_data [0:TP-1];
wire [LOGQ-1:0] i_rlk1_data [0:TP-1];
// mem <- final_op
wire [LOGQ-1:0] o_poly_data [0:TP-1];
// ntt control path
reg intt, load_psi, ntt_i_valid;
wire ntt_o_valid;
// ntt data path
wire [LOGQ-1:0] ntt_i_poly [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly [TP-1:0];
// fifo control path
reg fifo_ren, fifo_wen;
// fifo data path
wire [LOGQ-1:0] fifo_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_o_data [TP-1:0];
// hadamard control path
reg had_0_i_valid, had_1_i_valid;
wire had_0_o_valid, had_1_o_valid;
// hadamard data path
wire [LOGQ-1:0] had_0_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_0_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_0_o_poly   [TP-1:0];
wire [LOGQ-1:0] had_1_o_poly   [TP-1:0];
// accumulator control path
reg acc_sel, acc_0_ren, acc_0_wen, acc_0_rst, acc_1_ren, acc_1_wen, acc_1_rst;
wire acc_0_o_valid, acc_1_o_valid, acc_0_done, acc_1_done;
// accumulator data path
wire [LOGQ-1:0] acc_0_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_0_o_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_o_poly [TP-1:0];
// final op control path
reg fn_i_valid;
wire fn_o_valid;
// final op data path
wire [LOGQ-1:0] fn_i_poly [TP-1:0];
wire [LOGQ-1:0] fn_o_poly [TP-1:0];



q_mux #(
    .LOGL (LOGL),
    .LOGQ (LOGQ),
    .LOGQH(LOGQH)
) q_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(ctr_L),
    .qH(qH)
);


relin_mem #(
    .LOGQ(LOGQ),
    .LOGL(LOGL),
    .TP(TP)
) relin_mem_inst (
    .clk(clk),
    .rst(rst),
    .i_psi_en(i_psi_en),
    .i_psi_ready(i_psi_ready),
    .i_psi_valid(i_psi_valid),
    .i_psi_done(i_psi_done),
    .i_psi_id(i_psi_id),
    .i_psi_poly(i_psi_poly),
    .i_poly_en(i_poly_en),
    .i_poly_ready(i_poly_ready),
    .i_poly_valid(i_poly_valid),
    .i_poly_done(i_poly_done),
    .i_poly_id(i_poly_id),
    .i_poly_data(i_poly_data),
    .i_rlk0_en(i_rlk0_en),
    .i_rlk0_ready(i_rlk0_ready),
    .i_rlk0_valid(i_rlk0_valid),
    .i_rlk0_done(i_rlk0_done),
    .i_rlk0_id(i_rlk0_id),
    .i_rlk0_data(i_rlk0_data),
    .i_rlk1_en(i_rlk1_en),
    .i_rlk1_ready(i_rlk1_ready),
    .i_rlk1_valid(i_rlk1_valid),
    .i_rlk1_done(i_rlk1_done),
    .i_rlk1_id(i_rlk1_id),
    .i_rlk1_data(i_rlk1_data),
    .o_poly_en(o_poly_en),
    .o_poly_ready(o_poly_ready),
    .o_poly_done(o_poly_done),
    .o_poly_id(o_poly_id),
    .o_poly_data(o_poly_data),
    .relin_t(relin_t)
);


ntt_wrapper #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP)
) ntt_wrapper_inst (
    .clk     (clk        ),
    .rst     (rst        ),
    .load_q  (load_q     ),
    .load_psi(load_psi   ),
    .qH      (qH         ),
    .intt    (intt       ),
    .i_valid (ntt_i_valid),
    .i_poly (ntt_i_poly),
    .psi     (i_psi_poly ),
    .o_poly (ntt_o_poly),
    .o_valid (ntt_o_valid)
);


relin_fifo #(
    .K   (1 << (LOGN - LOGTP)),
    .TP  (TP                 ),
    .LOGQ(LOGQ               )
) relin_fifo_inst (
    .clk(clk),
    .rst(rst),
    .ren(fifo_ren),
    .wen(fifo_wen),
    .i_data(fifo_i_data),
    .o_data(fifo_o_data)
);

hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) hadamard_inst_0 (
    .clk(clk),
    .rst(rst),
    .qH(qH),
    .load_q(load_q),
    .i_valid(had_0_i_valid),
    .o_valid(had_0_o_valid),
    .A(had_0_i_poly_A),
    .B(had_0_i_poly_B),
    .C(had_0_o_poly)
);


hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) hadamard_inst_1 (
    .clk(clk),
    .rst(rst),
    .qH(qH),
    .load_q(load_q),
    .i_valid(had_1_i_valid),
    .o_valid(had_1_o_valid),
    .A(had_1_i_poly_A),
    .B(had_1_i_poly_B),
    .C(had_1_o_poly)
);


accumulator #(
    .LOGK (LOGN-LOGTP),
    .LOGQ (LOGQ      ),
    .LOGQH(LOGQH     ),
    .TP   (TP        )
) accumulator_inst_0 (
    .clk(clk),
    .rst(rst | acc_0_rst),
    .ren(acc_0_ren),
    .wen(acc_0_wen),
    .done(acc_0_done),
    .load_q(load_q),
    // .id(acc_0_id),
    .qH(qH),
    .A(acc_0_i_poly),
    .o_valid(acc_0_o_valid),
    .C(acc_0_o_poly)
);


accumulator #(
    .LOGK (LOGN-LOGTP),
    .LOGQ (LOGQ      ),
    .LOGQH(LOGQH     ),
    .TP   (TP        )
) accumulator_inst_1 (
    .clk(clk),
    .rst(rst | acc_1_rst),
    .ren(acc_1_ren),
    .wen(acc_1_wen),
    .done(acc_1_done),
    .load_q(load_q),
    // .id(acc_1_id),
    .qH(qH),
    .A(acc_1_i_poly),
    .o_valid(acc_1_o_valid),
    .C(acc_1_o_poly)
);


final_op #(
    .LOGQ(LOGQ),
    .LOGQH(LOGQH),
    .LOGN(LOGN),
    .TP(TP)
) final_op_inst (
    .clk(clk),
    .rst(rst),
    .load_q(load_q),
    .qH(qH),
    .i_valid(fn_i_valid),
    .A(fn_i_poly),
    .B(      ),
    .o_valid(fn_o_valid),
    .C(fn_o_poly)
);


always @(posedge clk) begin
    if (rst) begin
        ctr_L <= 0;
    end
    else if (ctr_L_inc) begin
        ctr_L <= ctr_L + 1;
    end
    else if (ctr_L_rst) begin
        ctr_L <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        ctr_poly <= 0;
    end
    else if (ctr_poly_inc) begin
        ctr_poly <= ctr_poly + 1;
    end
    else if (ctr_poly_rst) begin
        ctr_poly <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        ctr_rlk <= 0;
    end
    else if (ctr_rlk_inc) begin
        ctr_rlk <= ctr_rlk + 1;
    end
    else if (ctr_rlk_rst) begin
        ctr_rlk <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        ctr_acc <= 0;
    end
    else if (ctr_acc_inc) begin
        ctr_acc <= ctr_acc + 1;
    end
    else if (ctr_acc_rst) begin
        ctr_acc <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign ntt_i_poly    [i] = (intt)? ((acc_sel) ? acc_0_o_poly[TP] : acc_1_o_poly[TP]) : i_poly_data[i];
        assign fifo_i_data   [i] = ntt_o_poly    [i];
        assign had_0_i_poly_A[i] = fifo_o_data   [i];
        assign had_1_i_poly_A[i] = fifo_o_data   [i];
        assign had_0_i_poly_B[i] = i_rlk0_data   [i];
        assign had_1_i_poly_B[i] = i_rlk1_data   [i];
        assign acc_0_i_poly  [i] = had_0_o_poly  [i];
        assign acc_1_i_poly  [i] = had_1_o_poly  [i];
        assign fn_i_poly     [i] = ntt_o_poly    [i];
        assign o_poly_data   [i] = fn_o_poly     [i];
    end
endgenerate




always @(*) begin

    next_state = state;

    case (state)
        ST_IDLE: begin
            if (start)
                next_state = ST_LOAD_Q;
            ctr_L_rst = 1;
            ctr_poly_rst = 1;
            ctr_rlk_rst = 1;
        end
        ST_LOAD_Q: begin
            load_q = 1;
            next_state = ST_LOAD_PSI_START_READ;
        end
        ST_LOAD_PSI_START_READ: begin
            if (i_psi_ready) begin
                i_psi_en = 1;
                i_psi_id = ctr_L;
                ctr_L_inc = 1;
                next_state = ST_LOAD_PSI_READ_UNTIL_DONE;
            end
        end
        ST_LOAD_PSI_READ_UNTIL_DONE: begin
            if (i_psi_valid) begin
                load_psi = 1;
            end
            if (i_psi_done) begin
                next_state = ST_NTT_HP_ACC;                
            end
        end
        ST_NTT_HP_ACC: begin
            if (i_poly_ready) begin
                if (ctr_poly < L) begin
                    i_poly_en = 1;
                    i_poly_id = ctr_poly;
                    ctr_poly_inc = 1;
                end
            end

            if (i_poly_valid) begin
                ntt_i_valid = 1;
            end

            if (ntt_o_valid) begin
                fifo_wen = 1;
                if (i_rlk0_ready && i_rlk1_ready) begin
                    if (ctr_rlk < L) begin
                        i_rlk0_en = 1;
                        i_rlk1_en = 1;
                        i_rlk0_id = ctr_rlk;
                        i_rlk1_id = ctr_rlk;
                        ctr_rlk_inc = 1;
                    end
                end
            end

            if (i_rlk0_valid && i_rlk1_valid) begin
                fifo_ren = 1;
                had_0_i_valid = 1;
                had_1_i_valid = 1;
            end

            if (had_0_o_valid) begin // assumption: had_0_o_valid and had_1_o_valid are synchronous
                acc_0_wen = 1;
                acc_1_wen = 1;
            end

            if (acc_0_done) begin
                ctr_acc_inc = 1;
                if (ctr_acc >= (L-1)) begin
                    next_state = ST_LOAD_IPSI_START_READ;
                end
            end
        end
        ST_LOAD_IPSI_START_READ: begin
            i_psi_inv = 1;
            i_psi_en = 1;
            next_state = ST_LOAD_PSI_READ_UNTIL_DONE;
        end
        ST_LOAD_IPSI_READ_UNTIL_DONE: begin
            intt = 1;
            if (i_psi_valid) begin
                load_psi = 1;
            end
            if (i_psi_done) begin
                ctr_acc_rst = 1;
                ctr_poly_rst = 1;
                ctr_rlk_rst = 1;
                next_state = ST_INTT_0_START;                
            end
        end
        ST_INTT_0_START: begin
            acc_0_ren = 1;
            next_state = ST_INTT_FN;
        end
        ST_INTT_FN: begin
            if (acc_0_o_valid) begin
                ntt_i_valid = 1;
            end
            if (acc_0_done) begin
                acc_1_ren = 1;
            end

            if (acc_1_o_valid) begin
                ntt_i_valid = 1;
            end    
            intt = 1;
            if (ntt_o_valid) begin
                fn_i_valid = 1;
                ctr_poly_inc = 1;
            end
            if (fn_o_valid) begin
                o_poly_en = 1; // todo: did bot use o_poly_ready
                o_poly_id = (ctr_L << 1) + ctr_rlk; //todo: involve ctr_rlk
                ctr_rlk_inc = 1;
                if (ctr_rlk == 1) begin
                    next_state = ST_WAIT_WRITE;
                end
            end
        end
        ST_WAIT_WRITE: begin
            if (o_poly_done) begin
                if (ctr_L < L) begin
                    next_state = ST_LOAD_PSI_START_READ;
                    acc_0_rst = 1;
                    acc_1_rst = 1;
                    ctr_poly_rst = 1;
                    ctr_rlk_rst = 1;        
                end
                else begin
                    next_state = ST_IDLE;
                    done = 1;
                end
            end
        end
    endcase


end


endmodule