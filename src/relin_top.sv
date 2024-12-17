`include "relin_interface.sv"

module relin_top
   #(   
        parameter L        = 30  , // Number of primes
        parameter W        = 64  , // Word size
        parameter LOGN     = 16  , // Ring size
        parameter TP       = 32  , // Coefficient throughput
        parameter NT       = 1024, // Number of twiddles that must be loaded
        parameter NTT_LAT  = 2000, // NTT latency
        parameter HBM_LAT  = 10  , // HBM latency
        parameter HP_LAT   = 15  , // Hadamard product latency
        parameter ACC_LAT  = 3   , // Accum. latency
        parameter FN_LAT   = 100 , // Final op latency
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        relin_t.master     relin_t
    );


localparam D = 32; // bit-width for g.p. counter


typedef enum reg[10:0] {
    ST_IDLE        = 11'b00000000001,
    ST_LOAD_Q      = 11'b00000000010,
    ST_LOAD_PSI    = 11'b00000000100,
    ST_NTT         = 11'b00000001000,
    ST_LOAD_IPSI   = 11'b00000010000,
    ST_INTT        = 11'b00000100000,
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


reg [D-1:0] ctr; // general purpose counter 
reg ctr_inc;
reg ctr_rst;

reg [$clog(L)-1:0] ctr_poly;
reg ctr_poly_inc;
reg ctr_poly_rst;

reg [$clog(L)-1:0] ctr_rlk;
reg ctr_rlk_inc;
reg ctr_rlk_rst;


reg [$clog(L)-1:0] ctr_L; // counter for L
reg ctr_L_inc;
reg ctr_L_rst;

wire [W-1:0] q;
reg  load_q;

wire [W-1:0] ntt_in     [TP-1:0];
wire [W-1:0] ntt_out    [TP-1:0];
reg          intt;
reg          load_psi;
wire         ntt_out_valid;
wire         ntt_done;
reg          ntt_i_poly_valid;

wire [W-1:0] had_in_A   [TP*2-1:0];
wire [W-1:0] had_in_B   [TP*2-1:0];
wire [W-1:0] had_out    [TP*2-1:0];


wire [W-1:0] acc_in     [TP*2-1:0];
wire [W-1:0] acc_out    [TP*2-1:0];
reg          acc_wen;
reg          acc_sel;
reg          acc_rst;
reg          acc_ren;

wire [W-1:0] fn_in      [TP-1:0];
wire [W-1:0] fn_out     [TP-1:0];



q_mux #(
    .L(L),
    .W(W)
) q_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(ctr_L),
    .q(q)
);



ntt_wrapper #(
    .W(W),
    .LOGN(LOGN),
    .TP(TP)
) ntt_wrapper_inst (
    .clk(clk),
    .rst(rst),
    .load_q(load_q),
    .load_psi(load_psi),
    .intt(intt),
    .q(q),
    .psi_valid(relin_t.r_psi_valid),
    .psi(relin_t.r_psi),
    .i_poly_valid(ntt_i_poly_valid),
    .i_poly(ntt_in),
    .done(ntt_done),
    .o_poly_valid(ntt_out_valid),
    .o_poly(ntt_out)
);



hadamart #(
    .W(W),
    .TP(TP*2)
) hadamart_inst (
    .clk(clk),
    .rst(rst),
    .q(q),
    .A(had_in_A),
    .B(had_in_B),
    .C(had_out)
);



accumulator #(
    .W(W),
    .TP(TP*2)
) accumulator_inst (
    .clk(clk),
    .rst(rst | acc_rst),
    .wen(acc_wen),
    .ren(acc_ren),
    .load_q(load_q),
    .q(q),
    .A(acc_in),
    .C(acc_out)
);


final_op #(
    .W(W),
    .TP(TP)
) final_op_inst (
    .clk(clk),
    .rst(rst),
    .A(o_data),
    .C(o_data)
);



// for (genvar i = 0; i < TP; i = i + 1) begin
    
//     always @(posedge clk) begin
//         ntt_out_q[i] <= ntt_out[i];
//         had_out_q[i] <= had_out[i];
//         acc_out_q[i] <= acc_out[i];
//         fn_out_q [i] <= fn_out[i];
//     end

// end

// for (genvar i = TP; i < TP*2; i = i + 1) begin
    
//     always @(posedge clk) begin
//         had_out_q[i] <= had_out[i];
//         acc_out_q[i] <= acc_out[i];
//     end

// end


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
        ctr <= 0;
    end
    else if (ctr_inc) begin
        ctr <= ctr + 1;
    end
    else if (ctr_rst) begin
        ctr <= 0;
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
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


for (genvar i = 0; i < TP; i = i + 1) begin
    assign ntt_in  [i   ] = (intt)? ((acc_sel)? acc_out[i+TP]: acc_out[i]): relin_t.r_poly[i];
    assign had_in_A[i   ] = ntt_out        [i   ];
    assign had_in_A[i+TP] = ntt_out        [i   ];
    assign had_in_B[i   ] = relin_t.r_rlk_0[i   ];
    assign had_in_B[i+TP] = relin_t.r_rlk_1[i   ];
    assign acc_in  [i   ] = had_out        [i   ];
    assign acc_in  [i+TP] = had_out        [i+TP];
    assign fn_in   [i   ] = acc_out        [i   ];
end


assign relin_t.rw_idy = ctr_L;
assign relin_t.r_idx  = ctr;


always @(*) begin

    intt      = 0;
    ntt_i_poly_valid = 0;
    acc_wen   = 1;
    acc_ren   = 0;
    acc_sel   = 0;
    acc_rst   = 0;
    load_q    = 0;
    load_psi  = 0;
    ctr_inc   = 0;
    ctr_rst   = 0;
    ctr_L_inc = 0;
    ctr_L_rst = 0;
    ctr_poly_inc = 0;
    ctr_poly_rst = 0;
    ctr_rlk_inc  = 0;
    ctr_rlk_rst  = 0;
    o_valid   = 0;

    next_state = state;

    relin_t.r_psi_inv   = 0;
    relin_t.r_psi_start  = 0;
    relin_t.r_poly_start = 0;
    relin_t.r_rlk_start  = 0;


    case (state)
        ST_IDLE: begin
            if (start)
                next_state = ST_LOAD_Q;
            ctr_L_rst = 1;
            ctr_rst = 1;
            ctr_poly_rst = 1;
            ctr_rlk_rst = 1;
        end
        ST_LOAD_Q: begin
            load_q = 1;
            next_state = ST_LOAD_PSI_START_READ;
        end
        ST_LOAD_PSI_START_READ: begin
            relin_t.r_psi_start = 1;
            next_state = ST_LOAD_PSI_READ_UNTIL_DONE;
        end
        ST_LOAD_PSI_READ_UNTIL_DONE: begin
            if (relin_t.psi_done) begin
                next_state = ST_NTT_START_POLY_READ;                
            end
        end
        ST_NTT_START_POLY_READ: begin
            relin_t.r_poly_start = 1;
            next_state = ST_NTT_HP_ACC;
        end
        ST_NTT_HP_ACC: begin
            ntt_i_poly_valid = relin_t.r_poly_valid;

            if (ntt_done) begin
                relin_t.r_rlk_start = 1;
            end

            if (relin_t.poly_done) begin
                if (ctr_poly < (L-1)) begin
                    relin_t.r_poly_start = 1;
                    ctr_poly_inc = 1; // todo: fix timing
                end
                else begin
                    ctr_poly_rst = 1;
                end
            end

            if (relin_t.rlk_done) begin
                if (ctr_rlk < (L-1)) begin
                    ctr_rlk_inc = 1; // todo: fix timing
                end
                else begin
                    next_state = ST_WAIT_HP_ACC;
                    ctr_rlk_rst = 1;
                end
            end
        end
        ST_WAIT_HP_ACC: begin
            if (ctr == (HP_LAT + ACC_LAT - 1)) begin  // wait until all polynomials are processed
                next_state = ST_LOAD_IPSI;
                ctr_rst = 1;
            end
            else
                ctr_inc = 1;
        end
        ST_LOAD_IPSI: begin
            relin_t.r_psi_inv = 1;
            acc_wen = 0;
            load_psi = 1;
            intt = 1;
            if (ctr == ((NT/TP)-1)) begin
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end
        ST_LOAD_IPSI_START_READ: begin
            relin_t.r_psi_inv = 1;
            relin_t.r_psi_start = 1;
            next_state = ST_LOAD_PSI_READ_UNTIL_DONE;
            acc_wen = 0;
            intt = 1;
            load_psi = 1;
        end
        ST_LOAD_IPSI_READ_UNTIL_DONE: begin
            acc_wen = 0;
            intt = 1;
            load_psi = 1;
            if (relin_t.psi_done) begin
                next_state = ST_INTT_START;
                ctr_rst = 1; 
            end
        end
        ST_INTT_START: begin
            ntt_i_poly_valid = 1;
            intt = 1;
            acc_wen = 0;
            acc_ren = 1;
            if (ctr <= ((1 << LOGN)/TP) - 1) begin
                next_state = ST_INTT_FN;
                ctr_rst = 1;
            end
            else
                ctr_inc = 1;
        end
        ST_INTT_WAIT_DONE: begin
            intt = 1;
            if (ntt_done) begin
                ctr_inc = 1;
            end
        end
        ST_FN: begin
            if (ctr > (FN_LAT - 1)) begin
                o_valid = 1;
            end
            if (ctr == ((1 << LOGN)/TP + FN_LAT - 1)) begin
                if (ctr_L == L) begin
                    ctr_L_rst = 1;
                    next_state = ST_IDLE;
                end
                else begin
                    ctr_L_inc = 1;
                    next_state = ST_LOAD_Q; // go to next prime
                    acc_rst = 1;
                end
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end
    endcase


end


endmodule