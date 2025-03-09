module relin_cu_accum
   #(   
        parameter L             = 30,
        parameter REN_DELAY     = 2 , // between Accumulator 1 Read Enable and Accumulator 0 Done
        parameter START_DELAY   = 2 , // for start_read
        parameter RESTART_DELAY = 2   // for restart
    )
    (
        input              clk         ,
        input              rst         ,
        input              restart     ,
        input              start_read  ,
        output reg         write_done  ,
        input              acc_0_done  ,
        input              acc_1_done  ,
        output reg         acc_0_ren   ,
        output reg         acc_1_ren
    );


localparam LOGL = $rtoi($ceil($clog2(L + 1)));
localparam LOGD = $rtoi($ceil($clog2(REN_DELAY)));

typedef enum reg[5:0] {
    ST_NTT                      = 6'b000001,
    ST_INTT_0                   = 6'b000010,
    ST_INTT_1                   = 6'b000100,
    ST_INTT_2                   = 6'b001000,
    ST_INTT_D                   = 6'b010000,
    ST_WAIT_RESTART             = 6'b100000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;

wire start_read_d;
wire restart_d;


wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;

wire [LOGD-1:0] ctr_d;
reg  ctr_d_inc;
reg  ctr_d_rst;


shift_reg #(
    .SHIFT (START_DELAY),
    .WIDTH (1)
)
start_read_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (start_read  ),
    .o_data (start_read_d)
);


shift_reg #(
    .SHIFT (RESTART_DELAY),
    .WIDTH (1)
)
restart_shift_reg_2
(
    .clk    (clk),
    .rst    (rst),
    .i_data (restart  ),
    .o_data (restart_d)
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

generate
if (REN_DELAY) begin
    counter #(
        .WIDTH   (LOGD),
        .AUTO_INC(0   )
    ) ctr_inst (
        .clk(clk),
        .rst(rst | ctr_d_rst),
        .inc(ctr_d_inc),
        .ctr(ctr_d)
    );
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
    if (REN_DELAY != 0) begin
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
                    if (REN_DELAY != 0) begin
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
            if (start_read_d) begin
                acc_0_ren = 1;
                next_state = ST_INTT_2;
            end
        end
        ST_INTT_2: begin
            if (acc_0_done) begin
                if (REN_DELAY == 0) begin
                    acc_1_ren = 1;
                    next_state = ST_WAIT_RESTART;
                end
                else begin
                    next_state = ST_INTT_D;
                end
            end
        end
        ST_INTT_D: begin
            if (REN_DELAY != 0) begin
                if (ctr_d == (REN_DELAY - 1)) begin
                    acc_1_ren = 1;
                    next_state = ST_WAIT_RESTART;
                    ctr_d_rst = 1;
                end
                else begin
                    ctr_d_inc = 1;
                end
            end
        end
        ST_WAIT_RESTART: begin
            if (restart_d) begin
                next_state = ST_NTT;
            end
        end
    endcase
end


endmodule