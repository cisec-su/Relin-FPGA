module relin_cu_p0_ntt
   #(   
        parameter L               = 30, // loads L + 1 polynomials
        parameter ID_WIDTH        = 4 ,
        parameter LOAD_NTT_DELAY  = 2 ,
        parameter LOAD_INTT_DELAY = 2 ,
        parameter LOAD_Q_DELAY    = 1 ,
        parameter FEED_PSI_DELAY  = 2
    )
    (
        input                     clk          ,
        input                     rst          ,
        input                     start        ,
        input                     load_ntt     ,
        input                     load_intt    ,
        input                     i_p0_ready   ,
        input                     i_p0_valid   ,
        input                     i_p0_done    ,
        output reg                i_p0_en      ,
        output reg [ID_WIDTH-1:0] i_p0_id     ,
        output reg [LOGL    -1:0] i_p0_idx     ,
        output reg                intt         ,
        output reg                load_q       ,
        output reg [LOGL    -1:0] q_id         ,
        output                    intt_ready   ,
        output reg                i_valid_ntt  ,
        output reg                i_valid_psi  ,
        output reg                feed_psi     ,
        input                     psi_r_done   ,
        output reg                busy
    );

`include "relin_mem.svh"

localparam LOGL  = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[15:0] {
    ST_IDLE                      = 16'b0000000000000001,
    ST_LOAD_Q                    = 16'b0000000000000010,
    ST_LOAD_PSI_START            = 16'b0000000000000100,
    ST_LOAD_PSI_WAIT_DONE        = 16'b0000000000001000,
    ST_LOAD_POLY_START           = 16'b0000000000010000,
    ST_LOAD_POLY_WAIT_DONE       = 16'b0000000000100000,
    ST_LOAD_IPSI_START           = 16'b0000000001000000,
    ST_LOAD_IPSI_WAIT_DONE       = 16'b0000000010000000,
    ST_READY                     = 16'b0000010000000000,
    ST_LOAD_Q_1                  = 16'b0000100000000000,
    ST_USE_CACHE_PSI_START       = 16'b0001000000000000,
    ST_CACHE_PSI_START           = 16'b0010000000000000,
    ST_CACHE_PSI_WAIT_DONE       = 16'b0100000000000000,
    ST_USE_CACHE_PSI_WAIT_DONE   = 16'b1000000000000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


wire [LOGL-1:0] ctr_L;
wire [LOGL-1:0] ctr_L_;
reg  ctr_L_inc;
reg  ctr_L_rst;

wire [LOGL-1:0] ctr_poly;
reg  ctr_poly_inc;
reg  ctr_poly_rst;

reg intt_set, intt_clr;

wire load_ntt_d, load_intt_d;

wire load_q_d, load_q_d_1;

reg intt_ready_int;


assign ctr_L_ = (ctr_L == 0) ? L : ctr_L - 1;


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_inst (
    .clk(clk),
    .rst(rst | ctr_poly_rst),
    .inc(ctr_poly_inc),
    .ctr(ctr_poly)
);


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_L_inst (
    .clk(clk),
    .rst(rst | ctr_L_rst),
    .inc(ctr_L_inc),
    .ctr(ctr_L)
);


shift_reg #(
    .LAT   (LOAD_INTT_DELAY),
    .WIDTH (1)
) load_intt_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (load_intt  ),
    .o_data (load_intt_d)
);


shift_reg #(
    .LAT   (LOAD_Q_DELAY),
    .WIDTH (1)
) load_q_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (load_q     ),
    .o_data (load_q_d   )
);


shift_reg #(
    .LAT   (FEED_PSI_DELAY),
    .WIDTH (1)
) load_q_shift_reg_1 (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (load_q_d  ),
    .o_data (load_q_d_1)
);


shift_reg #(
    .LAT   (LOAD_NTT_DELAY),
    .WIDTH (1)
) load_ntt_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (load_ntt  ),
    .o_data (load_ntt_d)
);


shift_reg #(
    .LAT   (1),
    .WIDTH (1)
) intt_ready_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (intt_ready_int),
    .o_data (intt_ready    )
);


always @(posedge clk) begin
    if (rst) begin
        intt <= 0;
    end
    else if (intt_set) begin
        intt <= 1;
    end
    else if (intt_clr) begin
        intt <= 0;
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



always @(*) begin

    next_state = state;
    busy = 1'b0;
    load_q = 1'b0;
    intt_set = 1'b0;
    intt_clr = 1'b0;
    intt_ready_int = 1'b0;
    ctr_poly_inc = 1'b0;
    ctr_poly_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;
    i_p0_en = 1'b0;
    i_p0_id = 0;
    i_p0_idx = 0;
    q_id = ctr_L_;
    i_valid_ntt = 1'b0;
    i_valid_psi = 1'b0;
    feed_psi = 1'b0;

    case (state)
        ST_IDLE: begin
            if (start) begin
                next_state = ST_LOAD_Q;
                intt_clr = 1;
            end
            ctr_L_rst = 1;
            ctr_poly_rst = 1;
        end
        ST_READY: begin
            if (load_intt_d) begin
                next_state = ST_LOAD_IPSI_START;
                intt_set = 1;
            end
            else if (load_ntt_d) begin
                next_state = ST_LOAD_Q;
                intt_clr = 1;
            end
            ctr_poly_rst = 1;
        end
        ST_LOAD_Q: begin
            busy = 1;
            load_q = 1;
            next_state = ST_LOAD_Q_1;
        end
        ST_LOAD_Q_1: begin
            busy = 1;
            if (load_q_d_1) begin
                if (ctr_L == 0) begin
                    next_state = ST_LOAD_PSI_START;
                end
                else begin
                    next_state = ST_USE_CACHE_PSI_START;
                end
            end
        end
        ST_USE_CACHE_PSI_START: begin
            feed_psi = 1;
            next_state = ST_USE_CACHE_PSI_WAIT_DONE;
        end
        ST_USE_CACHE_PSI_WAIT_DONE: begin
            if (psi_r_done) begin
                next_state = ST_LOAD_POLY_START;
            end
        end
        ST_LOAD_PSI_START: begin
            busy = 1;
            i_p0_id = `PSI;
            i_p0_idx = ctr_L_;
            if (i_p0_ready) begin
                i_p0_en = 1;
                next_state = ST_LOAD_PSI_WAIT_DONE;
            end
        end
        ST_LOAD_PSI_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_psi = 1;
                feed_psi = 1;
            end
            if (i_p0_done) begin
                next_state = ST_LOAD_POLY_START;
            end
        end
        ST_LOAD_POLY_START: begin
            busy = 1;
            i_p0_id = `POLY_2;
            i_p0_idx = ctr_poly;
            if (i_p0_ready) begin
                i_p0_en = 1;
                next_state = ST_LOAD_POLY_WAIT_DONE;
            end
        end
        ST_LOAD_POLY_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_ntt = 1;
            end
            if (i_p0_done) begin
                if (ctr_poly < (L - 1)) begin
                    next_state = ST_LOAD_POLY_START;
                    ctr_poly_inc = 1;
                end
                else begin
                    next_state = ST_READY;
                    ctr_poly_rst = 1;
                end
            end
        end
        ST_LOAD_IPSI_START: begin
            busy = 1;
            i_p0_idx = ctr_L_;
            i_p0_id = `PSI_INV;
            if (i_p0_ready) begin
                i_p0_en = 1;
                next_state = ST_LOAD_IPSI_WAIT_DONE;
            end
        end
        ST_LOAD_IPSI_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_psi = 1;
                feed_psi = 1;
            end
            if (i_p0_done) begin
                intt_ready_int = 1;
                next_state = ST_CACHE_PSI_START;
            end
        end
        ST_CACHE_PSI_START: begin
            busy = 1;
            i_p0_id = `PSI;
            i_p0_idx = ctr_L;
            if (i_p0_ready) begin
                i_p0_en = 1;
                next_state = ST_CACHE_PSI_WAIT_DONE;
            end
        end
        ST_CACHE_PSI_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_psi = 1;
            end
            if (i_p0_done) begin
                if (ctr_L < L) begin
                    next_state = ST_READY;
                    ctr_L_inc = 1;
                end
                else begin
                    next_state = ST_IDLE;
                    ctr_L_rst = 1;
                end
            end
        end        
    endcase
end


endmodule