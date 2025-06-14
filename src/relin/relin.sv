`include "relin_if.svh"

module relin
   #(   
        parameter L        = 30       , // number of primes
        parameter LOGQ     = 64       ,
        parameter LOGQH    = 17       ,
        parameter LOGN     = 16       ,
        parameter LOGTP    = 5        , // coefficient throughput
        parameter PSI_CC   = (1 << (LOGN - LOGTP))*3,
        // delay configuration between modules
        // parameter CU_P1_P2__HAD__DELAY      = 2 ,
        // parameter CU_P1_P2__FIFO__DELAY     = 2 ,
        parameter Q_MUX__NTT__DELAY         = 2 ,
        parameter Q_MUX__HAD__DELAY         = 2 ,
        parameter Q_MUX__ACC__DELAY         = 2 ,
        parameter Q_MUX__FN__DELAY          = 2 ,
        // parameter CU_OUT__CU_P0_NTT__DELAY  = 2 ,
        // parameter CU_OUT__CU_ACC__DELAY     = 2 ,
        // parameter FN__CU_P0_NTT__DELAY      = 2 ,
        parameter CU_ACC__CU_P0_NTT__DELAY  = 2 ,
        parameter ACC__NTT_MUX__DELAY       = 2 ,
        // parameter NTT__FEED_PSI__DELAY      = 2 ,
        parameter ACC0_REN__ACC1_REN__DELAY = 10,
        parameter CU_ACC__MAIN_FSM__DELAY   = 2
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        output         reg done  ,
        relin_t.master     relin_t
    );


/////////////////////////////////////////////////////////////////////////////////////////

`include "relin_mem.svh"

localparam LOGK = LOGN - LOGTP;
localparam K = 1 << LOGK;
localparam LOGL = $rtoi($ceil($clog2(L + 1)));
localparam TP = 1 << LOGTP;
localparam ID_WIDTH = $rtoi($ceil($clog2(`NUM_MEM_OBJ)));

/////////////////////////////////////////////////////////////////////////////////////////


wire [LOGQH-1:0] qH_ntt, qH_had, qH_acc, qH_fn;
wire [LOGQ-1:0] half_fn;
wire [LOGQ-1:0] q_inv_fn;
// fsm <-> ntt, hadamard, accumulator, final_op
reg load_q_g1;
reg load_q_g2;
wire load_q_ntt, load_q_had, load_q_acc, load_q_fn, fn_load_q_start;
wire load_q_g1_d;
// mem
wire i_p0_en, i_p0_valid, i_p0_done;
wire [LOGQ-1:0] i_p0_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p0_id;
wire [LOGL-1:0] i_p0_idx;
wire i_p1_en, i_p1_valid, i_p1_done;
wire [LOGQ-1:0] i_p1_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p1_id;
wire [LOGL-1:0] i_p1_idx;
wire [LOGL-1:0] i_p1_idy;
wire i_p2_en, i_p2_valid, i_p2_done;
wire [LOGQ-1:0] i_p2_data [TP-1:0];
wire [LOGL-1:0] i_p2_idx;
wire [LOGL-1:0] i_p2_idy;
wire o_p3_en, o_p3_done;
wire [LOGQ-1:0] o_p3_data [TP-1:0];
wire [ID_WIDTH-1:0] o_p3_id;
wire [LOGL-1:0] o_p3_idx;
// delayed mem
wire i_p1_valid_d, i_p2_valid_d;
wire i_p1_valid_d1, i_p2_valid_d1;
wire [LOGQ-1:0] i_p1_data_d [TP-1:0];
wire [LOGQ-1:0] i_p2_data_d [TP-1:0];
// ntt control path
wire intt;
wire ntt_i_valid, intt_i_valid, psi_i_valid, feed_psi, psi_r_done;
wire ntt_o_valid, intt_o_valid;
// ntt data path
wire [LOGQ-1:0] ntt_i_poly [TP-1:0];
wire [LOGQ-1:0] intt_i_poly [TP-1:0];
wire [LOGQ-1:0] ntt_i_psi [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly [TP-1:0];
// fifo control path
wire fifo_0_ren, fifo_0_wen;
wire fifo_1_ren, fifo_1_wen;
// wire p1_dis;
// fifo data path
wire [LOGQ-1:0] fifo_0_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_0_o_data [TP-1:0];
wire [LOGQ-1:0] fifo_1_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_1_o_data [TP-1:0];
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
wire acc_i_valid_0, acc_i_valid_1;
wire acc_1_ren, acc_o_valid;
// accumulator data path
wire [LOGQ-1:0] acc_i_poly_0 [TP-1:0];
wire [LOGQ-1:0] acc_i_poly_1 [TP-1:0];
wire [LOGQ-1:0] acc_o_poly   [TP-1:0];
// final op control path
wire fn_i_valid;
wire fn_o_valid;
wire fn_i_done;
// final op data path
wire [LOGQ-1:0] fn_i_poly_A [TP-1:0];
wire [LOGQ-1:0] fn_i_poly_B [TP-1:0];
wire [LOGQ-1:0] fn_o_poly   [TP-1:0];
// cu_p0_ntt <-> cu_p1_p2
// wire acc_write_done;
wire acc_start_read;


wire o_valid;
reg cu_p0_start;
reg cu_out_start;

wire cu_p0_load_intt, cu_p0_intt_ready;

wire rlk0_i_valid, poly01_i_valid;
wire poly01_i_valid_p, poly01_en;

wire done_write;


relin_q_loader #(
    .L       (L      ),
    .LOGQ    (LOGQ   ),
    .LOGQH   (LOGQH  ),
    .DELAY_G1_A (Q_MUX__NTT__DELAY),
    .DELAY_G1_B (Q_MUX__HAD__DELAY),
    .DELAY_G1_C (Q_MUX__ACC__DELAY),
    .DELAY_G2_A (Q_MUX__FN__DELAY )
) relin_q_loader_inst (
    .clk     (clk    ),
    .rst     (rst    ),
    .load_q_g1(load_q_g1),
    .load_q_g2(load_q_g2),//fn_load_q_start),
    .qH_g1_A (qH_ntt ),
    .qH_g1_B (qH_had ),
    .qH_g1_C (qH_acc ),
    .qH_g2_A (qH_fn  ),
    .half_g2_A (half_fn),
    .q_inv_g2_A(q_inv_fn),
    .load_q_g1_A(load_q_ntt),
    .load_q_g1_B(load_q_had),
    .load_q_g1_C(load_q_acc),
    .load_q_g2_A(load_q_fn) ,
    .done_g1(load_q_g1_d)
);


relin_mem #(
    .LOGQ    (LOGQ    ),
    .LOGN    (LOGN    ),
    .LOGL    (LOGL    ),
    .ID_WIDTH(ID_WIDTH),
    .TP      (TP      )
) relin_mem_inst (
    .clk        (clk        ),
    .rst        (rst        ),
    .i_p0_en    (i_p0_en    ),
    .i_p0_id   (i_p0_id   ),
    .i_p0_idx   (i_p0_idx   ),
    .i_p0_valid (i_p0_valid ),
    .i_p0_done  (i_p0_done  ),
    .i_p0_data  (i_p0_data  ),
    .i_p1_en    (i_p1_en    ),
    .i_p1_id    (i_p1_id    ),
    .i_p1_idx   (i_p1_idx   ),
    .i_p1_idy   (i_p1_idy   ),
    .i_p1_valid (i_p1_valid ),
    .i_p1_done  (i_p1_done  ),
    .i_p1_data  (i_p1_data  ),
    .i_p2_en    (i_p2_en    ),
    .i_p2_idx   (i_p2_idx   ),
    .i_p2_idy   (i_p2_idy   ),
    .i_p2_valid (i_p2_valid ),
    .i_p2_done  (i_p2_done  ),
    .i_p2_data  (i_p2_data  ),
    .o_p3_en    (o_p3_en    ),
    .o_p3_id    (o_p3_id    ),
    .o_p3_idx   (o_p3_idx   ),
    .o_p3_done  (o_p3_done  ),
    .o_p3_data  (o_p3_data  ),
    .relin_t    (relin_t    )
);


relin_cu_p0_ntt #(
    .L              (L       ),
    .ID_WIDTH       (ID_WIDTH)
) relin_cu_p0_ntt_inst (
    .clk        (clk           ),
    .rst        (rst           ),
    .start      (cu_p0_start   ),
    // .load_intt  (cu_p0_load_intt),
    .i_p0_en    (i_p0_en       ),
    .i_p0_valid (i_p0_valid    ),
    .i_p0_id    (i_p0_id       ),
    .i_p0_idx   (i_p0_idx      ),
    .i_p0_done  (i_p0_done     ),
    .ntt_i_valid(ntt_i_valid   ),
    .psi_i_valid(psi_i_valid   ),
    .intt_ready (cu_p0_intt_ready)
);

relin_ntt_mux #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP),
    .INTT_DELAY(ACC__NTT_MUX__DELAY),
    .PSI_CC(PSI_CC)
) relin_ntt_mux_inst (
    .clk           (clk           ),
    .rst           (rst           ),
    .load_q        (load_q_ntt    ),
    .psi_valid     (psi_i_valid   ),
    .qH            (qH_ntt        ),
    .i_valid_ntt   (ntt_i_valid   ),
    .i_valid_intt  (intt_i_valid  ),
    .i_poly_ntt    (ntt_i_poly    ),
    .i_poly_intt   (intt_i_poly   ),
    .psi           (ntt_i_psi     ),
    .o_poly        (ntt_o_poly    ),
    .o_valid_ntt   (ntt_o_valid   ),
    .o_valid_intt  (intt_o_valid  )
);


relin_cu_p1_p2 #(
    .L(L),
    .ID_WIDTH(ID_WIDTH)
    // .HAD_EN_DELAY(CU_P1_P2__HAD__DELAY ),
    // .P1_DIS_DELAY(CU_P1_P2__FIFO__DELAY)
) relin_cu_p1_p2_inst (
    .clk       (clk        ),
    .rst       (rst        ),
    .en        (ntt_o_valid),// | poly01_en),
    .i_p1_en   (i_p1_en    ),
    .i_p1_id   (i_p1_id    ),
    .i_p1_idx  (i_p1_idx   ),
    .i_p1_idy  (i_p1_idy   ),
    .i_p1_valid(i_p1_valid ),
    .i_p1_done (i_p1_done  ),
    .i_p2_en   (i_p2_en    ),
    .i_p2_idx  (i_p2_idx   ),
    .i_p2_idy  (i_p2_idy   ),
    .i_p2_done (i_p2_done  ),
    .rlk0_i_valid (rlk0_i_valid),
    .poly01_i_valid (poly01_i_valid)
);


relin_fifo #(
    .K   (K   ),
    .TP  (TP  ),
    .LOGQ(LOGQ)
) relin_fifo_inst_0 (
    .clk(clk),
    .rst(rst),
    .ren(fifo_0_ren),
    .wen(fifo_0_wen),
    .i_data(fifo_0_i_data),
    .o_data(fifo_0_o_data)
);


// relin_fifo #(
//     .K   (K   ),
//     .TP  (TP  ),
//     .LOGQ(LOGQ)
// ) relin_fifo_inst_1 (
//     .clk(clk),
//     .rst(rst),
//     .ren(fifo_1_ren),
//     .wen(fifo_1_wen),
//     .i_data(fifo_1_i_data),
//     .o_data(fifo_1_o_data)
// );


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


relin_accum_wrapper #(
    .L          (L),
    .START_DELAY(CU_ACC__CU_P0_NTT__DELAY),
    .READ_DELAY (ACC0_REN__ACC1_REN__DELAY),
    .LOGK  (LOGN-LOGTP),
    .LOGQ  (LOGQ      ),
    .LOGQH (LOGQH     ),
    .LOGTP (LOGTP     )
) relin_accum_wrapper_inst (
    .clk     (clk          ),
    .rst     (rst          ),
    .start_read (acc_start_read),
    // .write_done (acc_write_done),
    .load_q  (load_q_acc   ),
    .qH      (qH_acc       ),
    .i_valid_0 (acc_i_valid_0),
    .i_poly_0  (acc_i_poly_0 ),
    .i_valid_1 (acc_i_valid_1),
    .i_poly_1  (acc_i_poly_1 ),
    .o_valid (acc_o_valid),
    .o_poly  (acc_o_poly )
);


// relin_final_op_wrapper #(
//     .LOGQ (LOGQ      ),
//     .LOGQH(LOGQH     ),
//     .LOGK (LOGN-LOGTP),
//     .LOGTP(LOGTP     ),
//     .L    (L         )
// ) relin_final_op_inst (
//     .clk    (clk          ),
//     .rst    (rst          ),
//     .load_q (load_q_fn    ),
//     .qH     (qH_fn        ),
//     .i_valid(fn_i_valid   ),
//     .halfmod(half_fn      ),
//     .q_inv  (q_inv_fn     ),
//     .A      (fn_i_poly_A  ),
//     .B      (fn_i_poly_B  ),
//     .o_valid(fn_o_valid   ),
//     .i_done (fn_i_done    ),
//     .C      (fn_o_poly    )
// );


relin_cu_out #(
    .L           (L       ),
    .ID_WIDTH    (ID_WIDTH)
    // .START_DELAY (CU_OUT__CU_ACC__DELAY)
) relin_cu_out_inst (
    .clk         (clk           ),
    .rst         (rst           ),
    // .start       (cu_out_start  ),
    .o_valid     (o_valid       ),
    .o_p3_done   (o_p3_done     ),
    .o_p3_id     (o_p3_id       ),
    .o_p3_idx    (o_p3_idx      ),
    .o_p3_en     (o_p3_en       ),
    .done        (done_write    )
); 


// pattern_gen #(
//     .FEED(2),
//     .POLL(0)
// ) pattern_gen_inst (
//     .clk    (clk),
//     .rst    (rst),
//     .i_en   (intt_o_valid    ),
//     .o_en   (poly01_en       ),
//     // .i_valid(poly01_i_valid  ),
//     .o_valid(poly01_i_valid_p)
// );

wire intt_o_valid_d;

shift_reg #(
    .LAT   (1),
    .WIDTH (1)
)
intt_o_valid_shift_reg
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (intt_o_valid  ),
    .o_data (intt_o_valid_d)
);

// data path connections
for (genvar i = 0; i < TP; i = i + 1) begin
    assign ntt_i_psi      [i] = i_p0_data     [i];
    assign ntt_i_poly     [i] = i_p0_data     [i]; 
    assign intt_i_poly    [i] = acc_o_poly    [i];
    assign fifo_0_i_data  [i] = ntt_o_poly    [i];
    // assign fifo_1_i_data  [i] = ntt_o_poly    [i];
    assign had_0_i_poly_A [i] = fifo_0_o_data [i];
    assign had_0_i_poly_B [i] = i_p1_data     [i];
    assign had_1_i_poly_A [i] = fifo_0_o_data [i];
    assign had_1_i_poly_B [i] = i_p2_data     [i];
    assign acc_i_poly_0   [i] = had_0_o_poly  [i];
    assign acc_i_poly_1   [i] = had_1_o_poly  [i];
    assign fn_i_poly_A    [i] = fifo_0_o_data [i];
    assign fn_i_poly_B    [i] = {LOGQ{1'b0}}; //i_p1_data     [i];
    assign o_p3_data      [i] = ntt_o_poly    [i];//fn_o_poly     [i];
end

// control path connections
assign intt_i_valid = acc_o_valid;

assign fifo_0_wen = ntt_o_valid;// | intt_o_valid;
// assign fifo_1_wen = ntt_o_valid;
assign fifo_0_ren = i_p1_valid;// | intt_o_valid_d;
// assign fifo_1_ren = i_p2_valid_d;

assign had_0_i_valid = i_p1_valid;
assign had_1_i_valid = i_p2_valid; // we assume that i_p2_valid is always valid when rlk0_i_valid is valid

assign acc_i_valid_0 = had_0_o_valid;
assign acc_i_valid_1 = had_1_o_valid;

// assign fn_i_valid = intt_o_valid_d;//poly01_i_valid_p;

assign o_valid = intt_o_valid;//fn_o_valid;


assign acc_start_read  = cu_p0_intt_ready;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////     ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////            ///////////////////////////////////////////////////////////
//            ////////////////////////////////////    MAIN FSM    //////////////////////////////////////                 //
////////////////////////////////////////////////////            ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////     ///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


typedef enum reg[10:0] {
    ST_IDLE                = 11'b00000000001,
    ST_OP                  = 11'b00000000100,
    ST_WAIT_FN_DONE        = 11'b00000010000,
    ST_WAIT_W_DONE         = 11'b00000100000,
    ST_DONE                = 11'b00001000000,
    ST_LOAD_Q_G1           = 11'b00010000000,
    ST_LOAD_Q_G1_WAIT_DONE = 11'b00100000000,
    ST_LOAD_Q_G2           = 11'b01000000000,
    ST_WAIT_ACC_O_VALID    = 11'b10000000000
} t_state;


(* fsm_encoding = "none" *) t_state state;
t_state next_state;

wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;
wire acc_o_valid_d;


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_L_inst (
    .clk(clk),
    .rst(rst | ctr_rst),
    .inc(ctr_inc),
    .ctr(ctr)
);


always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


shift_reg #(
    .LAT   (CU_ACC__MAIN_FSM__DELAY),
    .WIDTH (1)
) acc_o_valid_sr (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (acc_o_valid),
    .o_data (acc_o_valid_d)
);


always @(*) begin

    load_q_g1 = 0;
    load_q_g2 = 0;

    next_state = state;

    cu_p0_start  = 0;

    ctr_rst = 0;
    ctr_inc = 0;

    done = 0;

    case (state)
        ST_IDLE: begin
            ctr_rst = 1;
            if (start) begin
                next_state = ST_LOAD_Q_G1;
            end
        end
        ST_LOAD_Q_G1: begin
            load_q_g1 = 1;
            next_state = ST_OP;
        end
        ST_LOAD_Q_G1_WAIT_DONE: begin
            if (load_q_g1_d) begin
                next_state = ST_OP;
            end
            else begin
                next_state = ST_LOAD_Q_G1_WAIT_DONE;
            end
        end
        ST_OP: begin
            cu_p0_start = 1;
            next_state = ST_WAIT_ACC_O_VALID;
        end        
        ST_WAIT_ACC_O_VALID: begin
            if (acc_o_valid_d) begin
                next_state = ST_LOAD_Q_G2;
            end
        end
        ST_LOAD_Q_G2: begin
            load_q_g2 = 1;
            // if (ctr == 0) begin
            //     next_state = ST_WAIT_FN_DONE;                
            // end
            // else begin
                next_state = ST_WAIT_W_DONE;
            // end
        end
        // ST_WAIT_FN_DONE: begin
        //     if (fn_i_done) begin
        //         ctr_inc = 1;
        //         next_state = ST_LOAD_Q_G1;
        //     end
        // end
        ST_WAIT_W_DONE: begin
            if (done_write) begin
                if (ctr == L) begin
                    next_state = ST_DONE;
                end
                else begin
                    ctr_inc = 1;
                    next_state = ST_LOAD_Q_G1;
                end
            end
        end
        ST_DONE: begin
            done = 1;
            next_state = ST_IDLE;
        end
    endcase
end

endmodule