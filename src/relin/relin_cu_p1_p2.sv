module relin_cu_p1_p2
   #(   
        parameter L        = 30,
        parameter ID_WIDTH = 4 ,
        parameter HAD_EN_DELAY = 2
    )
    (
        input                     clk         ,
        input                     rst         ,
        input                     en          ,
        input                     i_p1_ready  ,
        output reg                i_p1_en     ,
        output reg [ID_WIDTH-1:0] i_p1_id     ,
        output reg [LOGL-1:0]     i_p1_idx    ,
        output reg [LOGL-1:0]     i_p1_idy    ,
        input                     i_p1_valid  ,
        input                     i_p2_ready  ,
        output reg                i_p2_en     ,
        output reg [ID_WIDTH-1:0] i_p2_idx    ,
        output reg [LOGL-1:0]     i_p2_idy    ,
        input                     i_p2_valid  ,
        output                    had_en
    );

`include "relin_mem.svh"


localparam LOGL  = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[10:0] {
    ST_LOAD_RLK                  = 11'b00000000010,
    ST_WAIT_VALID                = 11'b00010000000,
    ST_WAIT_VALID_0              = 11'b00100000000,
    ST_WAIT_VALID_1              = 11'b01000000000,
    ST_WAIT_VALID_2              = 11'b10000000000,
    ST_LOAD_POLY_0               = 11'b00000000100,
    ST_LOAD_POLY_1               = 11'b00000001000,
    ST_WAIT_READY_0              = 11'b00000010000,
    ST_WAIT_READY_1              = 11'b00000100000,
    ST_WAIT_READY_2              = 11'b00001000000        
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

reg had_en_int;

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


shift_reg #(
    .LAT   (HAD_EN_DELAY),
    .WIDTH (1)
)
ren_shift_reg
(
    .clk    (clk),
    .rst    (rst),
    .i_data (had_en_int),
    .o_data (had_en    )
);


always @(posedge clk) begin
    if (rst) begin
        state <= ST_LOAD_RLK;
    end
    else begin
        state <= next_state;
    end
end


assign ctr_L_ = (ctr_L == 0) ? L : ctr_L - 1;



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
    had_en_int = 1'b0;

    case (state)
        ST_LOAD_RLK: begin
            had_en_int = 1;
            if (en) begin
                if (i_p1_ready == 0 || i_p2_ready == 0) begin
                    next_state = ST_WAIT_READY_0;
                end
                else begin
                    i_p1_id = `RLK_0;
                    i_p1_idx = ctr_L_;
                    i_p1_en = 1;
                    i_p1_idy = ctr;
                    i_p2_idx = ctr_L_;
                    i_p2_en = 1;
                    i_p2_idy = ctr;
                    if (ctr >= (L - 1)) begin
                        next_state = ST_WAIT_VALID;
                        ctr_rst = 1;
                    end
                    else
                        ctr_inc = 1;    
                end
            end
        end
        ST_WAIT_READY_0: begin
            had_en_int = 1;
            if (i_p1_ready && i_p2_ready) begin
                i_p1_idx = ctr_L_;
                i_p1_en = 1;
                i_p1_idy = ctr;
                i_p2_idx = ctr_L_;
                i_p2_en = 1;
                i_p2_idy = ctr;
                if (ctr >= (L - 1)) begin
                    next_state = ST_WAIT_VALID;
                    ctr_rst = 1;
                end
                else begin
                    next_state = ST_LOAD_RLK;
                    ctr_inc = 1;
                end
            end
        end
        ST_WAIT_VALID: begin
            had_en_int = 1;
            if (i_p1_valid && i_p2_valid) begin
                next_state = ST_LOAD_POLY_0;
            end
            else if (i_p1_valid) begin
                next_state = ST_WAIT_VALID_0;
            end
            else if (i_p2_valid) begin
                next_state = ST_WAIT_VALID_1;
            end
        end
        ST_WAIT_VALID_0: begin
            had_en_int = 1;
            if (i_p2_valid) begin
                next_state = ST_LOAD_POLY_0;
            end
        end
        ST_WAIT_VALID_1: begin
            had_en_int = 1;
            if (i_p1_valid) begin
                next_state = ST_LOAD_POLY_0;
            end
        end
        ST_LOAD_POLY_0: begin
            if (en) begin
                if (i_p1_ready) begin
                    i_p1_id = `POLY_0;
                    i_p1_idx = ctr_L_;
                    i_p1_en = 1;
                    next_state = ST_LOAD_POLY_1;
                end
                else begin
                    next_state = ST_WAIT_READY_1;
                end
            end
        end
        ST_WAIT_READY_1: begin
            if (i_p1_ready) begin
                i_p1_idx = ctr_L_;
                i_p1_en = 1;
                i_p1_idy = ctr;
                next_state = ST_LOAD_POLY_1;
            end
        end
        ST_LOAD_POLY_1: begin
            if (en) begin
                if (i_p1_ready) begin
                    i_p1_id = `POLY_1;
                    i_p1_idx = ctr_L_;
                    i_p1_en = 1;
                    if (ctr_L >= L) begin
                        ctr_L_rst = 1;
                    end
                    else begin
                        ctr_L_inc = 1;
                    end
                    next_state = ST_WAIT_VALID_2;    
                end
                else begin
                    next_state = ST_WAIT_READY_2;
                end
            end
        end
        ST_WAIT_READY_2: begin
            if (i_p1_ready) begin
                i_p1_idx = ctr_L_;
                i_p1_en = 1;
                i_p1_idy = ctr;
                if (ctr_L >= L) begin
                    ctr_L_rst = 1;
                end
                else begin
                    ctr_L_inc = 1;
                end
                next_state = ST_WAIT_VALID_2;    
            end
        end
        ST_WAIT_VALID_2: begin
            if (i_p1_valid) begin
                next_state = ST_LOAD_RLK;
            end
        end
        default: begin
            next_state = ST_LOAD_RLK;
        end
    endcase
end


endmodule