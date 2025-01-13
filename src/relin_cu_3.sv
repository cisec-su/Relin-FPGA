module relin_cu_3
   #(   
        parameter L = 30
    )
    (
        input                 clk         ,
        input                 start       ,
        input                 rst         ,
        input                 i_rlk0_ready,
        input                 i_rlk1_ready,
        input                 ntt_o_valid ,
        output reg            i_rlk0_en   ,
        output reg            i_rlk1_en   ,
        output reg [LOGL-1:0] i_rlk0_id
    );


localparam LOGL = $rtoi($ceil($clog2(L)));

typedef enum reg[10:0] {
    ST_IDLE                      = 11'b00000000001,
    ST_LOAD_RLK                  = 11'b00000000010
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;

reg [LOGL-1:0] ctr;
reg ctr_inc;
reg ctr_rst;


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


assign i_rlk0_id = ctr;
assign i_rlk1_id = ctr;


always @(*) begin

    next_state = state;
    i_rlk0_en = 1'b0;
    i_rlk1_en = 1'b0;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;

    case (state)
        ST_IDLE: begin // todo: add default state
            if (start) begin
                next_state = ST_LOAD_RLK;
            end
            ctr_rst = 1;
        end
        ST_LOAD_RLK: begin
            if (ntt_o_valid) begin
                i_rlk0_en = 1;
                i_rlk1_en = 1;
                if (ctr >= L) begin
                    next_state = ST_IDLE;
                end
                else
                    ctr_inc = 1;
            end
        end
        default: begin
            next_state = ST_IDLE;
        end
    endcase
end


endmodule