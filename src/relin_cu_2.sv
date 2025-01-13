module relin_cu_2
   #(   
        parameter L     = 30,
        parameter DELAY = 2 // between Accumulator 1 Read Enable and Accumulator 0 Done
    )
    (
        input              clk         ,
        input              rst         ,
        input              start_read  ,
        output reg         write_done  ,
        input              acc_0_done  ,
        input              acc_1_done  ,
        output reg         acc_0_ren   ,
        output reg         acc_1_ren
    );


localparam LOGL = $rtoi($ceil($clog2(L)));
localparam LOGD = $rtoi($ceil($clog2(DELAY)));

typedef enum reg[10:0] {
    ST_NTT                      = 11'b00000000001,
    ST_INTT_0                   = 11'b00000000010,
    ST_INTT_1                   = 11'b00000000100,
    ST_INTT_2                   = 11'b00000001000,
    ST_INTT_D                   = 11'b00000010000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


reg [LOGL-1:0] ctr;
reg ctr_inc;
reg ctr_rst;

reg [LOGD-1:0] ctr_d;
reg ctr_d_inc;
reg ctr_d_rst;

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

generate
if (DELAY) begin
    always @(posedge clk) begin
        if (rst) begin
            ctr_d <= 0;
        end
        else if (ctr_d_inc) begin
            ctr_d <= ctr_d + 1;
        end
        else if (ctr_d_rst) begin
            ctr_d <= 0;
        end
    end
end   
endgenerate


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
    write_done = 1'b0;
    ctr_inc = 1'b0;
    ctr_rst = 1'b0;
    if (DELAY != 0) begin
        ctr_d_inc = 1'b0;
        ctr_d_rst = 1'b0;
    end
    acc_0_ren = 1'b0;
    acc_1_ren = 1'b0;

    case (state)
        ST_NTT: begin
            if (acc_0_done) begin
                if (ctr >= L) begin
                    next_state = ST_INTT_0;
                    ctr_rst = 1;
                    if (DELAY != 0) begin
                        ctr_d_rst = 1;
                    end
                end
                else begin
                    ctr_inc = 1'b1;
                end
            end
        end
        ST_INTT_0: begin
            write_done = 1'b1;
            next_state = ST_INTT_1;
        end
        ST_INTT_1: begin
            if (start_read) begin
                acc_0_ren = 1;
                next_state = ST_INTT_2;
            end
        end
        ST_INTT_2: begin
            if (acc_0_done) begin
                if (DELAY == 0) begin
                    acc_1_ren = 1;
                    next_state = ST_NTT;
                end
                else begin
                    next_state = ST_INTT_D;
                end
            end
        end
        ST_INTT_D: begin
            if (DELAY != 0) begin
                if (ctr_d == (DELAY - 1)) begin
                    acc_1_ren = 1;
                    next_state = ST_NTT;
                    ctr_d_rst = 1;
                end
                else begin
                    ctr_d_inc = 1;
                end
            end
        end
    endcase
end


endmodule