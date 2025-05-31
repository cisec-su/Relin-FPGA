module relin_cu_out
   #(   
        parameter L           = 30,
        parameter ID_WIDTH    = 4 ,
        parameter FN_I_DONE_DELAY = 2
    )
    (
        input                     clk         ,
        input                     rst         ,
        input                     start       ,
        input                     fn_i_done   ,
        input                     fn_o_valid  ,
        input                     o_p3_done   ,
        input                     o_p3_ready  ,
        output reg [ID_WIDTH-1:0] o_p3_id    ,
        output reg [LOGL    -1:0] o_p3_idx    ,
        output reg                o_p3_en     ,
        output reg                done_single ,
        output reg                done_all
    );

`include "relin_mem.svh"


localparam LOGL = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[10:0] {
    ST_IDLE                       = 11'b00000000001,
    ST_POLY_0_WRITE_START         = 11'b00000000010,
    ST_POLY_0_WRITE_WAIT_DONE     = 11'b00000000100,
    ST_POLY_1_WRITE_START         = 11'b00000001000,
    ST_POLY_1_WRITE_WAIT_DONE     = 11'b00000010000,
    ST_END                        = 11'b00000100000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;
wire fn_i_done_d;


shift_reg #(
    .LAT   (FN_I_DONE_DELAY),
    .WIDTH (1)
)
intt_done_shift_reg
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (fn_i_done   ),
    .o_data (fn_i_done_d )
);


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_inst (
    .clk(clk),
    .rst(rst | ctr_rst),
    .inc(ctr_inc),
    .ctr(ctr)
);


assign o_p3_idy = ctr;


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
    done_single = 1'b0;
    done_all    = 1'b0;
    ctr_inc     = 1'b0;
    ctr_rst     = 1'b0;
    o_p3_en     = 1'b0;
    o_p3_id     = 0;

    case (state)
        ST_IDLE: begin
            if (fn_i_done_d) begin
                next_state = ST_POLY_0_WRITE_START;
                done_single = 1;
            end
        end
        ST_POLY_0_WRITE_START: begin
            o_p3_idx = ctr;
            if (fn_o_valid & o_p3_ready) begin
                o_p3_id = `POLY_0;
                o_p3_en = 1'b1;
                next_state = ST_POLY_0_WRITE_WAIT_DONE;
            end
        end
        ST_POLY_0_WRITE_WAIT_DONE: begin
            if (o_p3_done) begin
                next_state = ST_POLY_1_WRITE_START;
            end
        end
        ST_POLY_1_WRITE_START: begin
            if (fn_o_valid & o_p3_ready) begin
                o_p3_id = `POLY_1;
                o_p3_en = 1'b1;
                next_state = ST_POLY_1_WRITE_WAIT_DONE;
            end
        end
        ST_POLY_1_WRITE_WAIT_DONE: begin
            if (o_p3_done) begin
                next_state = ST_END;
            end
        end
        ST_END: begin
            if (ctr == (L - 1)) begin
                done_all = 1;
                ctr_rst = 1;
                next_state = ST_IDLE;
            end
            else begin
                done_single = 1;
                ctr_inc = 1;
                next_state = ST_POLY_0_WRITE_START;
            end
        end
    endcase
end


endmodule