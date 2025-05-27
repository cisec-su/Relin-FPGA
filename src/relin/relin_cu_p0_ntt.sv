module relin_cu_p0_ntt
   #(   
        parameter L               = 30, // loads L + 1 polynomials
        parameter ID_WIDTH        = 4 ,
        parameter LOAD_NTT_DELAY  = 2 ,
        parameter LOAD_INTT_DELAY = 2
    )
    (
        input                     clk          ,
        input                     rst          ,
        input                     start        ,
        input                     load_ntt     ,
        input                     load_intt    ,
        input                     i_p0_ready   ,
        input                     i_p0_valid   ,
        input                     i_p0_done    ,
        output reg                i_p0_en      ,
        output reg [ID_WIDTH-1:0] i_p0_idx     ,
        output reg [LOGL    -1:0] i_p0_idy     ,
        output reg                intt         ,
        output reg                load_q       ,
        output reg [LOGL    -1:0] q_id         ,
        output reg                intt_ready   ,
        output reg                i_valid_ntt  ,
        output reg                i_valid_psi  ,
        output reg                busy
    );

`include "relin_mem.svh"

localparam LOGL  = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[10:0] {
    ST_IDLE                      = 11'b00000000001,
    ST_LOAD_Q                    = 11'b00000000010,
    ST_LOAD_PSI_START            = 11'b00000000100,
    ST_LOAD_PSI_WAIT_DONE        = 11'b00000001000,
    ST_LOAD_POLY_START           = 11'b00000010000,
    ST_LOAD_POLY_WAIT_DONE       = 11'b00000100000,
    ST_LOAD_IPSI_START           = 11'b00001000000,
    ST_LOAD_IPSI_WAIT_DONE       = 11'b00010000000,
    ST_READY                     = 11'b10000000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


wire [LOGL-1:0] ctr_L;
reg  ctr_L_inc;
reg  ctr_L_rst;

wire [LOGL-1:0] ctr_poly;
reg  ctr_poly_inc;
reg  ctr_poly_rst;

reg intt_set, intt_clr;

wire load_ntt_d, load_intt_d;

counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_inst (
    .clk(clk),
    .rst(rst | ctr_poly_rst),
    .inc(ctr_poly_inc),
    .ctr(ctr_poly)
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
    .LAT   (LOAD_INTT_DELAY),
    .WIDTH (1)
) load_intt_shift_reg (
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (load_intt  ),
    .o_data (load_intt_d)
);


shift_reg #(
    .LAT   (LOAD_NTT_DELAY),
    .WIDTH (1)
) load_ntt_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (load_ntt  ),
    .o_data (load_ntt_d)
);



always @(posedge clk) begin
    if (rst) begin
        intt <= 0;
    end
    else if (intt_set) begin
        intt <= 1;
    end
    else if (intt_clr) begin
        intt <= 0;
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
    busy = 1'b0;
    load_q = 1'b0;
    intt_set = 1'b0;
    intt_clr = 1'b0;
    intt_ready = 1'b0;
    ctr_poly_inc = 1'b0;
    ctr_poly_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;
    i_p0_en = 1'b0;
    i_p0_idx = 0;
    i_p0_idy = 0;
    q_id = ctr_L;
    i_valid_ntt = 1'b0;
    i_valid_psi = 1'b0;


    case (state)
        ST_IDLE: begin
            if (start) begin
                next_state = ST_LOAD_Q;
                intt_clr = 1;
            end
            ctr_L_rst = 1;
            ctr_poly_rst = 1;
        end
        ST_READY: begin
            if (load_intt_d) begin
                next_state = ST_LOAD_IPSI_START;
                intt_set = 1;
            end
            else if (load_ntt_d) begin
                next_state = ST_LOAD_Q;
                intt_clr = 1;
            end
            ctr_poly_rst = 1;
        end
        ST_LOAD_Q: begin
            busy = 1;
            load_q = 1;
            next_state = ST_LOAD_PSI_START;
        end
        ST_LOAD_PSI_START: begin
            busy = 1;
            if (i_p0_ready) begin
                i_p0_en = 1;
                i_p0_idx = `PSI;
                i_p0_idy = ctr_L;
                next_state = ST_LOAD_PSI_WAIT_DONE;
            end
        end
        ST_LOAD_PSI_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_psi = 1;
            end
            if (i_p0_done) begin
                next_state = ST_LOAD_POLY_START;
            end
        end
        ST_LOAD_POLY_START: begin
            busy = 1;
            if (i_p0_ready) begin
                i_p0_en = 1;
                i_p0_idx = `POLY_2;
                i_p0_idy = ctr_poly;
                next_state = ST_LOAD_POLY_WAIT_DONE;
            end
        end
        ST_LOAD_POLY_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_ntt = 1;
            end
            if (i_p0_done) begin
                if (ctr_poly < (L - 1)) begin
                    next_state = ST_LOAD_POLY_START;
                    ctr_poly_inc = 1;
                end
                else begin
                    next_state = ST_READY;
                    ctr_poly_rst = 1;
                end
            end
        end
        ST_LOAD_IPSI_START: begin
            busy = 1;
            if (i_p0_ready) begin
                i_p0_en = 1;
                i_p0_idx = `PSI_INV;
                i_p0_idy = ctr_L;
                next_state = ST_LOAD_IPSI_WAIT_DONE;
            end
        end
        ST_LOAD_IPSI_WAIT_DONE: begin
            busy = 1;
            if (i_p0_valid) begin
                i_valid_psi = 1;
            end
            if (i_p0_done) begin
                intt_ready = 1;
                if (ctr_L < L) begin
                    next_state = ST_READY;
                    ctr_L_inc = 1;
                end
                else begin
                    next_state = ST_IDLE;
                    ctr_L_rst = 1;
                end
            end
        end
    endcase
end


endmodule