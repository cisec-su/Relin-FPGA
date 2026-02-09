module relin_cu_p1_p2
   #(   
        parameter L        = 30,
        parameter ID_WIDTH = 4
    )
    (
        input                     clk         ,
        input                     rst         ,
        input                     en          ,
        output reg                i_p1_en     ,
        output reg [ID_WIDTH-1:0] i_p1_id     ,
        output reg [LOGL-1:0]     i_p1_idx    ,
        output reg [LOGL-1:0]     i_p1_idy    ,
        input                     i_p1_done   ,
        input                     i_p1_valid  ,
        output reg                i_p2_en     ,
        output reg [LOGL-1:0]     i_p2_idx    ,
        output reg [LOGL-1:0]     i_p2_idy    ,
        output reg                rlk0_i_valid,
        output reg                poly01_i_valid,
        input                     i_p2_done,
        output reg    [10:0]           state_p1_p2_out,
        output reg   [LOGL-1:0]           ctr_L_out,
        output reg   [LOGL-1:0]           ctr_L__out,
        output reg   [LOGL-1:0]           ctr_out
    );

`include "relin_mem.svh"


localparam LOGL  = $rtoi($ceil($clog2(L + 1)));

always @(posedge clk) begin
    state_p1_p2_out <= state;
    ctr_L_out <= ctr_L;
    ctr_L__out <= ctr_L_;
    ctr_out <= ctr;
end


typedef enum reg[10:0] {
    ST_LOAD_RLK                  = 11'b00000000001,
    ST_WAIT_DONE                 = 11'b00000000100,
    ST_WAIT_DONE_0               = 11'b00000001000,
    ST_WAIT_DONE_1               = 11'b00000010000,
    ST_LOAD_POLY_0               = 11'b00000100000,
    ST_WAIT_DONE_2               = 11'b00001000000,
    ST_LOAD_POLY_1               = 11'b00010000000,
    ST_WAIT_DONE_3               = 11'b00100000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;

wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;

wire [LOGL-1:0] ctr_L;
wire [LOGL-1:0] ctr_L_;
reg ctr_L_inc;
reg ctr_L_rst;

// reg p1_dis_int;

reg en_q;
reg en_q_clr;
wire en_int;


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_inst (
    .clk(clk),
    .rst(rst | ctr_rst),
    .inc(ctr_inc),
    .ctr(ctr)
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


always @(posedge clk) begin
    if (rst) begin
        state <= ST_LOAD_RLK;
    end
    else begin
        state <= next_state;
    end
end


always @(posedge clk) begin
    if (rst) begin
        en_q <= 1'b0;
    end
    else if (en_q_clr) begin
        en_q <= 1'b0;
    end
    else if (en) begin
        en_q <= 1'b1;
    end
end



assign ctr_L_ = (ctr_L == 0) ? L : ctr_L - 1;

assign en_int = en | en_q;


always @(*) begin

    next_state = state;
    i_p1_en = 1'b0;
    i_p1_idx = ctr_L_;
    i_p1_idy = ctr;
    i_p2_en = 1'b0;
    i_p2_idx = ctr_L_;
    i_p2_idy = ctr;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;
    i_p1_id = `RLK_0;
    en_q_clr = 1'b0;
    // p1_dis_int = 1'b0;

    rlk0_i_valid = i_p1_valid;
    poly01_i_valid = 1'b0;

    case (state)
        ST_LOAD_RLK: begin
            i_p1_id = `RLK_0;
            i_p1_idx = ctr_L_;
            i_p1_idy = ctr;
            i_p2_idx = ctr_L_;
            i_p2_idy = ctr;
            rlk0_i_valid = i_p1_valid;
            if (en_int) begin
                en_q_clr = 1;
                i_p1_en = 1;
                i_p2_en = 1;
                next_state = ST_WAIT_DONE;
            end
        end
        ST_WAIT_DONE: begin
            i_p1_id = `RLK_0;
            i_p1_idx = ctr_L_;
            i_p1_idy = ctr;
            i_p2_idx = ctr_L_;
            i_p2_idy = ctr;
            rlk0_i_valid = i_p1_valid;
            if (i_p1_done && i_p2_done) begin
                next_state = ST_LOAD_RLK;
                if (ctr >= (L - 1)) begin
                    ctr_rst = 1;
                    if (ctr_L >= L) begin
                        ctr_L_rst = 1;
                    end
                    else begin
                        ctr_L_inc = 1;
                    end
                    // if (ctr_L == 0) begin
                    //     next_state = ST_LOAD_RLK;
                    //     ctr_L_inc = 1;
                    // end
                    // else begin
                    //     next_state = ST_LOAD_POLY_0;
                    // end
                end
                else begin
                    ctr_inc = 1;
                end
            end
            else if (i_p2_done) begin
                next_state = ST_WAIT_DONE_0;
            end
            else if (i_p1_done) begin
                next_state = ST_WAIT_DONE_1;
            end
        end
        ST_WAIT_DONE_0: begin
            i_p1_id = `RLK_0;
            i_p1_idx = ctr_L_;
            i_p1_idy = ctr;
            i_p2_idx = ctr_L_;
            i_p2_idy = ctr;      
            rlk0_i_valid = i_p1_valid;
            if (i_p1_done) begin
                next_state = ST_LOAD_RLK;
                if (ctr >= (L - 1)) begin
                    ctr_rst = 1;
                    if (ctr_L >= L) begin
                        ctr_L_rst = 1;
                    end
                    else begin
                        ctr_L_inc = 1;
                    end
                    // if (ctr_L == 0) begin
                    //     next_state = ST_LOAD_RLK;
                    //     ctr_L_inc = 1;
                    // end
                    // else begin
                    //     next_state = ST_LOAD_POLY_0;
                    // end
                end
                else begin
                    ctr_inc = 1;
                end
            end
        end
        ST_WAIT_DONE_1: begin
            i_p1_id = `RLK_0;
            i_p1_idx = ctr_L_;
            i_p1_idy = ctr;
            i_p2_idx = ctr_L_;
            i_p2_idy = ctr;
            rlk0_i_valid = i_p1_valid;
            if (i_p2_done) begin
                next_state = ST_LOAD_RLK;
                if (ctr >= (L - 1)) begin
                    ctr_rst = 1;
                    if (ctr_L >= L) begin
                        ctr_L_rst = 1;
                    end
                    else begin
                        ctr_L_inc = 1;
                    end
                    // if (ctr_L == 0) begin
                    //     next_state = ST_LOAD_RLK;
                    //     ctr_L_inc = 1;
                    // end
                    // else begin
                    //     next_state = ST_LOAD_POLY_0;
                    // end
                end
                else begin
                    ctr_inc = 1;
                end
            end
        end
        ST_LOAD_POLY_0: begin
            i_p1_id = `POLY_0;
            i_p1_idx = ctr_L_;
            poly01_i_valid = i_p1_valid;
            if (en_int) begin
                i_p1_en = 1;
                en_q_clr = 1;
                next_state = ST_WAIT_DONE_2;
            end
        end
        ST_WAIT_DONE_2: begin
            i_p1_id = `POLY_0;
            i_p1_idx = ctr_L_;
            poly01_i_valid = i_p1_valid;
            if (i_p1_done) begin
                next_state = ST_LOAD_POLY_1;
            end
        end
        ST_LOAD_POLY_1: begin
            i_p1_id = `POLY_1;
            i_p1_idx = ctr_L_;
            poly01_i_valid = i_p1_valid;
            if (en_int) begin
                i_p1_en = 1;
                en_q_clr = 1;
                next_state = ST_WAIT_DONE_3;
            end
        end
        ST_WAIT_DONE_3: begin
            i_p1_id = `POLY_1;
            i_p1_idx = ctr_L_;
            poly01_i_valid = i_p1_valid;
            if (i_p1_done) begin
                next_state = ST_LOAD_RLK;
                if (ctr_L >= L) begin
                    ctr_L_rst = 1;
                end
                else begin
                    ctr_L_inc = 1;
                end
            end
        end
        default: begin
            next_state = ST_LOAD_RLK;
        end
    endcase
end


endmodule