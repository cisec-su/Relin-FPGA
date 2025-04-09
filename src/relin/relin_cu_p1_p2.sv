module relin_cu_p1_p2
   #(   
        parameter L        = 30,
        parameter ID_WIDTH = 4
    )
    (
        input                     clk         ,
        input                     rst         ,
        input                     en          ,
        input                     i_p1_ready  ,
        output reg                i_p1_en     ,
        output reg [ID_WIDTH-1:0] i_p1_idx    ,
        output reg [LOGL-1:0]     i_p1_idy    ,
        input                     i_p2_ready  ,
        output reg                i_p2_en     ,
        output reg [ID_WIDTH-1:0] i_p2_idx    ,
        output reg [LOGL-1:0]     i_p2_idy
    );

`include "relin_mem.svh"


localparam LOGL  = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[10:0] {
    ST_LOAD_RLK                  = 11'b00000000010,
    ST_LOAD_POLY_0               = 11'b00000000100,
    ST_LOAD_POLY_1               = 11'b00000001000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;

wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;

wire [LOGL-1:0] ctr_L;
reg ctr_L_inc;
reg ctr_L_rst;

reg en_q;
wire en_clr, en_int;


always @(posedge clk) begin
    if (rst) begin
        en_q <= 1'b0;
    end
    else if (en_clr) begin
        en_q <= 1'b0;
    end
    else if (en) begin
        en_q <= 1'b1;
    end
end


assign en_int = en | en_q;
assign en_clr = i_p1_en;


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


always @(*) begin

    next_state = state;
    i_p1_en = 1'b0;
    i_p1_idx = 0;
    i_p1_idy = 0;
    i_p2_en = 1'b0;
    i_p2_idx = 0;
    i_p2_idy = 0;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;

    case (state)
        ST_LOAD_RLK: begin
            if (en_int) begin
                if (i_p1_ready & i_p2_ready) begin
                    i_p1_idx = `RLK_0;
                    i_p1_en = 1;
                    i_p1_idy = ctr;

                    i_p2_idx = `RLK_1;
                    i_p2_en = 1;
                    i_p2_idy = ctr;

                    if (ctr >= L) begin
                        next_state = ST_LOAD_POLY_0;
                        ctr_rst = 1;
                    end
                    else
                        ctr_inc = 1;
                end
            end
        end
        ST_LOAD_POLY_0: begin
            if (en_int) begin
                if (i_p1_ready) begin
                    i_p1_idx = `POLY_0;
                    i_p1_en = 1;
                    i_p1_idy = ctr_L;
                end
                next_state = ST_LOAD_POLY_1;
            end
        end
        ST_LOAD_POLY_1: begin
            if (en_int) begin
                if (i_p1_ready) begin
                    i_p1_idx = `POLY_1;
                    i_p1_en = 1;
                    i_p1_idy = ctr_L;
                    if (ctr_L >= (L - 1)) begin
                        ctr_L_rst = 1;
                    end
                    else begin
                        ctr_L_inc = 1;
                    end
                    next_state = ST_LOAD_RLK;    
                end
            end
        end
        default: begin
            next_state = ST_LOAD_RLK;
        end
    endcase
end


endmodule