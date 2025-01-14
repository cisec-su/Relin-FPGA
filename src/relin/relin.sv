`include "relin_if.svh"

module relin
   #(   
        parameter L        = 30       , // number of primes
        parameter LOGQ     = 64       ,
        parameter LOGQH    = 17       ,
        parameter LOGN     = 16       ,
        parameter LOGTP    = 5        , // coefficient throughput
        parameter NUM_PSI  = 1 << LOGN, // number of twiddles that must be loaded
        // delay configuration between modules
        parameter CU_OUT__ACC__DELAY        = 2 ,
        parameter CU_OUT__CU_ACC__DELAY     = 2 ,
        parameter CU_ACC__FN__DELAY         = 2 ,
        parameter Q_MUX__NTT__DELAY         = 2 ,
        parameter Q_MUX__HAD__DELAY         = 2 ,
        parameter Q_MUX__ACC__DELAY         = 2 ,
        parameter Q_MUX__FN__DELAY          = 2 ,
        parameter CU_OUT__CU_P0_NTT__DELAY  = 2 ,
        parameter CU_ACC__CU_P0_NTT__DELAY  = 2 ,
        parameter ACC0_REN__ACC1_REN__DELAY = 10  // must be configured based on HBM read latency
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        output             done  ,
        relin_t.master     relin_t
    );

`include "relin_mem.svh"

localparam LOGK = LOGN - LOGTP;
localparam K = 1 << LOGK;
localparam LOGL = $rtoi($ceil($clog2(L + 1)));
localparam TP = 1 << LOGTP;
localparam ID_WIDTH = $rtoi($ceil($clog2(`NUM_MEM_OBJ)));


wire [LOGQH-1:0] qH_ntt, qH_had, qH_acc, qH_fn;
// fsm <-> ntt, hadamard, accumulator, final_op
wire load_q, load_q_ntt, load_q_had, load_q_acc, load_q_fn;
// mem
wire i_p0_en, i_p0_ready, i_p0_valid, i_p0_done;
wire [LOGQ-1:0] i_p0_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p0_idx;
wire [LOGL-1:0] i_p0_idy;
wire i_p1_en, i_p1_ready, i_p1_valid, i_p1_done;
wire [LOGQ-1:0] i_p1_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p1_idx;
wire [LOGL-1:0] i_p1_idy;
wire i_p2_en, i_p2_ready, i_p2_valid, i_p2_done;
wire [LOGQ-1:0] i_p2_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p2_idx;
wire [LOGL-1:0] i_p2_idy;
wire o_p3_en, o_p3_ready, o_p3_done;
wire [LOGQ-1:0] o_p3_data [TP-1:0];
wire [ID_WIDTH-1:0] o_p3_idx;
wire [LOGL-1:0] o_p3_idy;
// delayed mem
wire i_p1_valid_d, i_p2_valid_d;
wire [LOGQ-1:0] i_p1_data_d [TP-1:0];
wire [LOGQ-1:0] i_p2_data_d [TP-1:0];
// ntt control path
wire intt;
wire i_valid_ntt, i_valid_intt_A, i_valid_intt_B;
wire ntt_o_valid;
// ntt data path
wire [LOGQ-1:0] i_poly_ntt [TP-1:0];
wire [LOGQ-1:0] i_poly_intt_A [TP-1:0];
wire [LOGQ-1:0] i_poly_intt_B [TP-1:0];
wire [LOGQ-1:0] i_psi_data [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly [TP-1:0];
// fifo control path
wire fifo_ren, fifo_wen;
// fifo data path
wire [LOGQ-1:0] fifo_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_o_data [TP-1:0];
// hadamard control path
wire had_0_i_valid, had_1_i_valid;
wire had_0_o_valid, had_1_o_valid;
// hadamard data path
wire [LOGQ-1:0] had_0_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_0_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_0_o_poly   [TP-1:0];
wire [LOGQ-1:0] had_1_o_poly   [TP-1:0];
// accumulator control path
wire acc_0_wen, acc_1_wen;
wire acc_0_ren, acc_1_ren;
wire acc_1_ren, acc_0_o_valid, acc_1_o_valid, acc_0_done, acc_1_done;
// accumulator data path
wire [LOGQ-1:0] acc_0_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_0_o_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_o_poly [TP-1:0];
// final op control path
wire fn_i_valid;
wire fn_o_valid;
wire fn_rst;
// final op data path
wire [LOGQ-1:0] fn_i_poly_A [TP-1:0];
wire [LOGQ-1:0] fn_i_poly_B [TP-1:0];
wire [LOGQ-1:0] fn_o_poly   [TP-1:0];
// cu_p0_ntt <-> cu_p1_p2
wire acc_write_done;
wire acc_start_read;
wire [LOGL-1:0] q_id;


relin_q_shift #(
    .LOGL    (LOGL   ),
    .LOGQ    (LOGQ   ),
    .LOGQH   (LOGQH  ),
    .DELAY_A (Q_MUX__NTT__DELAY),
    .DELAY_B (Q_MUX__HAD__DELAY),
    .DELAY_C (Q_MUX__ACC__DELAY),
    .DELAY_D (Q_MUX__FN__DELAY )
) relin_q_shift_inst (
    .clk     (clk    ),
    .rst     (rst    ),
    .load_q  (load_q ),
    .i       (q_id   ),
    .qH_A    (qH_ntt ),
    .qH_B    (qH_had ),
    .qH_C    (qH_acc ),
    .qH_D    (qH_fn  ),
    .load_q_A(load_q_ntt),
    .load_q_B(load_q_had),
    .load_q_C(load_q_acc),
    .load_q_D(load_q_fn )
);


relin_mem #(
    .LOGQ    (LOGQ    ),
    .LOGN    (LOGN    ),
    .LOGL    (LOGL    ),
    .ID_WIDTH(ID_WIDTH),
    .TP      (TP      ),
    .NUM_PSI (NUM_PSI )
) relin_mem_inst (
    .clk        (clk        ),
    .rst        (rst        ),
    .i_p0_en    (i_p0_en    ),
    .i_p0_idx   (i_p0_idx   ),
    .i_p0_idy   (i_p0_idy   ),
    .i_p0_ready (i_p0_ready ),
    .i_p0_valid (i_p0_valid ),
    .i_p0_done  (i_p0_done  ),
    .i_p0_data  (i_p0_data  ),
    .i_p1_en    (i_p1_en    ),
    .i_p1_idx   (i_p1_idx   ),
    .i_p1_idy   (i_p1_idy   ),
    .i_p1_ready (i_p1_ready ),
    .i_p1_valid (i_p1_valid ),
    .i_p1_done  (i_p1_done  ),
    .i_p1_data  (i_p1_data  ),
    .i_p2_en    (i_p2_en    ),
    .i_p2_idx   (i_p2_idx   ),
    .i_p2_idy   (i_p2_idy   ),
    .i_p2_ready (i_p2_ready ),
    .i_p2_valid (i_p2_valid ),
    .i_p2_done  (i_p2_done  ),
    .i_p2_data  (i_p2_data  ),
    .o_p3_en    (o_p3_en    ),
    .o_p3_idx   (o_p3_idx   ),
    .o_p3_idy   (o_p3_idy   ),
    .o_p3_ready (o_p3_ready ),
    .o_p3_done  (o_p3_done  ),
    .o_p3_data  (o_p3_data  ),
    .relin_t    (relin_t    )
);


relin_cu_p0_ntt #(
    .L              (L       ),
    .ID_WIDTH       (ID_WIDTH),
    .LOAD_NTT_DELAY (CU_OUT__CU_P0_NTT__DELAY),
    .LOAD_INTT_DELAY(CU_ACC__CU_P0_NTT__DELAY)
) relin_cu_p0_ntt_inst (
    .clk        (clk           ),
    .rst        (rst           ),
    .start      (start         ),
    .load_ntt   (done_single   ),
    .load_intt  (acc_write_done),
    .i_p0_en    (i_p0_en       ),
    .i_p0_valid (i_p0_valid    ),
    .i_p0_idx   (i_p0_idx      ),
    .i_p0_idy   (i_p0_idy      ),
    .i_p0_ready (i_p0_ready    ),
    .i_p0_done  (i_p0_done     ),
    .intt       (intt          ),
    .load_q     (load_q        ),
    .q_id       (q_id          ),
    .intt_ready (acc_start_read),
    .i_valid_ntt(i_valid_ntt   ),
    .busy       (              )
);


relin_ntt_mux #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP),
    .INTT_A_DELAY(2) // todo: set this
) relin_ntt_mux_inst (
    .clk           (clk           ),
    .rst           (rst           ),
    .load_q        (load_q_ntt    ),
    .load_psi      (i_psi_valid   ),
    .qH            (qH            ),
    .intt          (intt          ),
    .i_valid_ntt   (i_valid_ntt   ),
    .i_valid_intt_A(i_valid_intt_A),
    .i_valid_intt_B(i_valid_intt_B),
    .i_poly_ntt    (i_poly_ntt    ),
    .i_poly_intt_A (i_poly_intt_A ),
    .i_poly_intt_B (i_poly_intt_B ),
    .psi           (i_psi_data    ),
    .o_poly        (ntt_o_poly    ),
    .o_valid       (ntt_o_valid   )
);


relin_cu_p1_p2 #(
    .L(L)
) relin_cu_p1_p2_inst (
    .clk       (clk        ),
    .rst       (rst        ),
    .en        (ntt_o_valid),
    .i_p1_ready(i_p1_ready ),
    .i_p1_en   (i_p1_en    ),
    .i_p1_idx  (i_p1_idx   ),
    .i_p1_idy  (i_p1_idy   ),
    .i_p2_ready(i_p2_ready ),
    .i_p2_en   (i_p2_en    ),
    .i_p2_idx  (i_p2_idx   ),
    .i_p2_idy  (i_p2_idy   )
);


relin_fifo #(
    .K   (K   ),
    .TP  (TP  ),
    .LOGQ(LOGQ)
) relin_fifo_inst (
    .clk(clk),
    .rst(rst),
    .ren(fifo_ren),
    .wen(fifo_wen),
    .i_data(fifo_i_data),
    .o_data(fifo_o_data)
);


relin_hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) relin_hadamard_inst_0 (
    .clk    (clk           ),
    .rst    (rst           ),
    .qH     (qH_had        ),
    .load_q (load_q_had    ),
    .i_valid(had_0_i_valid ),
    .o_valid(had_0_o_valid ),
    .A      (had_0_i_poly_A),
    .B      (had_0_i_poly_B),
    .C      (had_0_o_poly  )
);


relin_hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) relin_hadamard_inst_1  (
    .clk    (clk           ),
    .rst    (rst           ),
    .qH     (qH_had        ),
    .load_q (load_q_had    ),
    .i_valid(had_1_i_valid ),
    .o_valid(had_1_o_valid ),
    .A      (had_1_i_poly_A),
    .B      (had_1_i_poly_B),
    .C      (had_1_o_poly  )
);


relin_accum #(
    .LOGK  (LOGN-LOGTP),
    .LOGQ  (LOGQ      ),
    .LOGQH (LOGQH     ),
    .TP    (TP        )
) relin_accum_inst_0 (
    .clk     (clk          ),
    .rst     (rst | acc_rst),
    .ren     (acc_0_ren    ),
    .wen     (acc_0_wen    ),
    .done    (acc_0_done   ),
    .load_q  (load_q_acc   ),
    .qH      (qH_acc       ),
    .A       (acc_0_i_poly ),
    .o_valid (acc_0_o_valid),
    .C       (acc_0_o_poly )
);


relin_accum #(
    .LOGK  (LOGN-LOGTP),
    .LOGQ  (LOGQ      ),
    .LOGQH (LOGQH     ),
    .TP    (TP        )
) relin_accum_inst_1 (
    .clk     (clk          ),
    .rst     (rst | acc_rst),
    .ren     (acc_1_ren    ),
    .wen     (acc_1_wen    ),
    .done    (acc_1_done   ),
    .load_q  (load_q_acc   ),
    .qH      (qH_acc       ),
    .A       (acc_1_i_poly ),
    .o_valid (acc_1_o_valid),
    .C       (acc_1_o_poly )
);


relin_cu_accum #(
    .L          (L),
    .REN_DELAY  (ACC0_REN__ACC1_REN__DELAY),
    .START_DELAY(CU_ACC__CU_P0_NTT__DELAY )
) relin_cu_accum_inst (
    .clk        (clk           ),
    .rst        (rst           ),
    .start_read (acc_start_read),
    .write_done (acc_write_done),
    .acc_0_done (acc_0_done    ),
    .acc_1_done (acc_1_done    ),
    .acc_0_ren  (acc_0_ren     ),
    .acc_1_ren  (acc_1_ren     )
);


relin_final_op #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .TP   (TP   )
) relin_final_op_inst (
    .clk    (clk          ),
    .rst    (rst | fn_rst ),
    .load_q (load_q_fn    ),
    .qH     (qH_fn        ),
    .i_valid(fn_i_valid   ),
    .A      (fn_i_poly_A  ),
    .B      (fn_i_poly_B  ),
    .o_valid(fn_o_valid   ),
    .C      (fn_o_poly    )
);


relin_cu_out #(
    .L          (L       ),
    .START_DELAY(CU_OUT__CU_ACC__DELAY),
    .ID_WIDTH   (ID_WIDTH)
) relin_cu_out_inst (
    .clk         (clk           ),
    .rst         (rst           ),
    .start       (acc_write_done),
    .fn_o_valid  (fn_o_valid    ),
    .o_p3_done   (o_p3_done     ),
    .o_p3_ready  (o_p3_ready    ),
    .o_p3_idx    (o_p3_idx      ),
    .o_p3_idy    (o_p3_idy      ),
    .o_p3_en     (o_p3_en       ),
    .done_single (done_single   ),
    .done_all    (done          )
); 


shift_reg #(
    .LAT   (CU_ACC__FN__DELAY),
    .WIDTH (1)
) fn_rst_shift_reg (
    .clk    (clk           ),
    .rst    (rst           ),
    .i_data (acc_write_done),
    .o_data (fn_rst        )
);


shift_reg #(
    .LAT   (CU_OUT__ACC__DELAY),
    .WIDTH (1)
) acc_rst_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (done_single),
    .o_data (acc_rst    )
);



shift_reg #(
    .LAT   (1),
    .WIDTH (1)
) i_p1_valid_shift_reg (
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (i_p1_valid  ),
    .o_data (i_p1_valid_d)
);


shift_reg #(
    .LAT   (1),
    .WIDTH (1)
) i_p2_valid_shift_reg (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (i_p2_valid),
    .o_data (i_p2_valid_d)
);


shift_reg_arr #(
    .LAT   (1   ),
    .WIDTH (LOGQ),
    .LENGTH(TP  ),
    .RST_EN(0   )
) i_p1_data_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (i_p1_data  ),
    .o_data (i_p1_data_d)
);


shift_reg_arr #(
    .LAT   (1   ),
    .WIDTH (LOGQ),
    .LENGTH(TP  ),
    .RST_EN(0   )
) i_p2_data_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (i_p2_data  ),
    .o_data (i_p2_data_d)
);



// data path connections
generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign i_psi_data     [i] = i_p0_data     [i];
        assign i_poly_ntt     [i] = i_p0_data     [i];
        assign i_poly_intt_A  [i] = acc_0_o_poly  [i];
        assign i_poly_intt_B  [i] = acc_1_o_poly  [i];
        assign fifo_i_data    [i] = ntt_o_poly    [i];
        assign had_0_i_poly_A [i] = fifo_o_data   [i];
        assign had_1_i_poly_A [i] = fifo_o_data   [i];
        assign had_0_i_poly_B [i] = i_p1_data_d   [i];
        assign had_1_i_poly_B [i] = i_p2_data_d   [i];
        assign acc_0_i_poly   [i] = had_0_o_poly  [i];
        assign acc_1_i_poly   [i] = had_1_o_poly  [i];
        assign fn_i_poly_A    [i] = fifo_o_data   [i];
        assign fn_i_poly_B    [i] = i_p1_data_d   [i];
        assign o_p3_data      [i] = fn_o_poly     [i];
    end
endgenerate


// control path connections
assign i_valid_intt_A = acc_0_o_valid;
assign i_valid_intt_B = acc_1_o_valid;

assign fifo_wen = ntt_o_valid;
assign fifo_ren = i_p1_valid_d;

assign had_0_i_valid = i_p1_valid_d;
assign had_1_i_valid = i_p2_valid_d;

assign acc_0_wen = had_0_o_valid;
assign acc_1_wen = had_1_o_valid;

assign fn_i_valid = i_p1_valid_d;



endmodule