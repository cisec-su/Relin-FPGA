module relin_cu_4
   #(   
        parameter L = 30
    )
    (
        input              clk         ,
        input              rst         ,
        input              start       ,
        input              o_poly_done ,
        input              fn_o_valid  ,
        input              o_poly_ready,
        output [LOGL-1:0]  o_poly_id   ,
        output reg         o_poly_en   ,
        output reg         done_base   ,
        output reg         done_all
    );


localparam LOGL = $rtoi($ceil($clog2(L)));


typedef enum reg[10:0] {
    ST_IDLE                       = 11'b00000000001,
    ST_POLY_0_WRITE_START         = 11'b00000000010,
    ST_POLY_0_WRITE_WAIT_DONE     = 11'b00000000100,
    ST_POLY_1_WRITE_START         = 11'b00000001000,
    ST_POLY_1_WRITE_WAIT_DONE     = 11'b00000010000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


reg [LOGL:0] ctr;
reg ctr_inc;
reg ctr_rst;


assign o_poly_id = ctr;


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
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


always @(*) begin

    next_state = state;
    done_base = 1'b0;
    done_all = 1'b0;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;
    o_poly_en = 1'b0;

    case (state)
        ST_IDLE: begin
            if (start)
                next_state = ST_POLY_0_WRITE_START;
        end
        ST_POLY_0_WRITE_START: begin
            if (fn_o_valid & o_poly_ready) begin
                o_poly_en = 1'b1;
                next_state = ST_POLY_0_WRITE_WAIT_DONE;
            end
        end
        ST_POLY_0_WRITE_WAIT_DONE: begin
            if (o_poly_done) begin
                next_state = ST_POLY_1_WRITE_START;
            end
        end
        ST_POLY_1_WRITE_START: begin
            if (fn_o_valid & o_poly_ready) begin
                o_poly_en = 1'b1;
                next_state = ST_POLY_1_WRITE_WAIT_DONE;
            end
        end
        ST_POLY_1_WRITE_WAIT_DONE: begin
            if (o_poly_done) begin
                if (ctr == (L - 1)) begin
                    done_all = 1;
                    ctr_rst = 1;
                end
                else begin
                    done_base = 1;
                    ctr_inc = 1;
                end
                next_state = ST_IDLE;
            end
        end
    endcase
end


endmodule