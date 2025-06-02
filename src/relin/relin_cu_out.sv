module relin_cu_out
   #(   
        parameter L           = 30,
        parameter ID_WIDTH    = 4 ,
        parameter START_DELAY = 2
    )
    (
        input                     clk         ,
        input                     rst         ,
        input                     start       ,
        input                     fn_o_valid  ,
        input                     o_p3_done   ,
        input                     o_p3_ready  ,
        output reg [ID_WIDTH-1:0] o_p3_id    ,
        output reg [LOGL    -1:0] o_p3_idx    ,
        output reg                o_p3_en     ,
        output reg                fn_load_q_start ,
        output     [LOGL    -1:0] fn_q_id     ,
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
    ST_END                        = 11'b00000100000,
    ST_LOAD_Q                     = 11'b00001000000,
    ST_WAIT_IDONE                 = 11'b00010000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;

wire start_d;


shift_reg #(
    .LAT   (START_DELAY),
    .WIDTH (1)
)
start_shift_reg
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (start       ),
    .o_data (start_d     )
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



always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end

assign fn_q_id = (ctr == 0) ? L : ctr - 1;

always @(*) begin

    next_state  = state;
    done_all    = 1'b0;
    ctr_inc     = 1'b0;
    ctr_rst     = 1'b0;
    o_p3_en     = 1'b0;
    o_p3_id     = 0;
    o_p3_idx    = ctr;
    fn_load_q_start = 1'b0;

    case (state)
        ST_IDLE: begin
            if (start_d) begin
                next_state = ST_LOAD_Q;                
            end
        end
        // we assume that there is enough time to load the q before the first operation
        // this is because start comes from accumulator write done, and input of fn is intt output, which causes enough time
        ST_LOAD_Q: begin
            fn_load_q_start = 1'b1;
            if (ctr == 0) begin
                next_state = ST_WAIT_IDONE;
            end
            else begin
                next_state = ST_POLY_0_WRITE_START;
            end
        end
        ST_WAIT_IDONE: begin
            if (start_d) begin
                next_state = ST_LOAD_Q;
                ctr_inc = 1'b1;
            end
        end
        ST_POLY_0_WRITE_START: begin
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
            next_state = ST_IDLE;
            if (ctr == L) begin
                done_all = 1;
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end
    endcase
end


endmodule