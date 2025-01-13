module relin_cu_2
   #(   
        parameter L = 30
    )
    (
        input              clk         ,
        input              rst         ,
        input              acc_0_done  ,
        input              acc_1_done  ,
        output reg         acc_0_ren   ,
        output reg         acc_1_ren   ,
        input              feed_intt   ,
        output reg         load_intt
    );


localparam LOGL = $rtoi($ceil($clog2(L)));


typedef enum reg[10:0] {
    ST_NTT                      = 11'b00000000001,
    ST_INTT_0                   = 11'b00000000010,
    ST_INTT_1                   = 11'b00000000100,
    ST_INTT_2                   = 11'b00000001000
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
        state <= ST_NTT;
    end
    else begin
        state <= next_state;
    end
end


always @(*) begin

    next_state = state;
    load_intt = 1'b0;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;
    acc_0_ren = 1'b0;
    acc_1_ren = 1'b0;

    case (state)
        ST_NTT: begin
            if (acc_0_done) begin
                if (ctr >= L) begin
                    next_state = ST_INTT_0;
                    ctr_rst = 1;
                end
                else begin
                    ctr_inc = 1'b1;
                end
            end
        end
        ST_INTT_0: begin
            load_intt = 1'b1;
            next_state = ST_INTT_1;
        end
        ST_INTT_1: begin
            if (feed_intt) begin
                acc_0_ren = 1;
                next_state = ST_INTT_2;
            end
        end
        ST_INTT_2: begin
            if (acc_0_done) begin
                acc_1_ren = 1;
                next_state = ST_NTT;
            end
        end
    endcase
end


endmodule