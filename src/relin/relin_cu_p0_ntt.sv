module relin_cu_p0_ntt
   #(   
        parameter L               = 30,
        parameter ID_WIDTH        = 4
    )
    (
        input                     clk          ,
        input                     rst          ,
        input                     start        ,
        input                     i_p0_valid   ,
        input                     i_p0_done    ,
        output reg                i_p0_en      ,
        output reg [ID_WIDTH-1:0] i_p0_id      ,
        output reg [LOGL    -1:0] i_p0_idx     ,
        output reg                ntt_i_valid  ,
        output reg                psi_i_valid  ,
        output reg                intt_ready   
    );

`include "relin_mem.svh"

localparam LOGL  = $rtoi($ceil($clog2(L + 1)));


typedef enum reg[15:0] {
    ST_IDLE                      = 16'b0000000000000001,
    ST_LOAD_PSI_START            = 16'b0000000000000100,
    ST_LOAD_PSI_WAIT_DONE        = 16'b0000000000001000,
    ST_LOAD_POLY_START           = 16'b0000000000010000,
    ST_LOAD_POLY_WAIT_DONE       = 16'b0000000000100000,
    ST_LOAD_IPSI_START           = 16'b0000000001000000,
    ST_LOAD_IPSI_WAIT_DONE       = 16'b0000000010000000,
    ST_INTT_READY                = 16'b0000001000000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


wire [LOGL-1:0] ctr_L;
wire [LOGL-1:0] ctr_L_;
reg  ctr_L_inc;
reg  ctr_L_rst;

wire [LOGL-1:0] ctr_poly;
reg  ctr_poly_inc;
reg  ctr_poly_rst;


assign ctr_L_ = (ctr_L == 0) ? L : ctr_L - 1;


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
    ctr_poly_inc = 1'b0;
    ctr_poly_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;
    i_p0_en = 1'b0;
    i_p0_id = `POLY_2;
    i_p0_idx = ctr_L_;
    ntt_i_valid = 1'b0;
    psi_i_valid = 1'b0;

    intt_ready = 1'b0;

    case (state)
        ST_IDLE: begin
            if (start) begin
                next_state = ST_LOAD_PSI_START;
            end
            // ctr_L_rst = 1;
            // ctr_poly_rst = 1;
        end
        ST_LOAD_PSI_START: begin
            i_p0_id = `PSI;
            i_p0_idx = ctr_L_;
            i_p0_en = 1;
            next_state = ST_LOAD_PSI_WAIT_DONE;
        end
        ST_LOAD_PSI_WAIT_DONE: begin
            i_p0_id = `PSI;
            i_p0_idx = ctr_L_;
            psi_i_valid = i_p0_valid;
            if (i_p0_done) begin
                next_state = ST_LOAD_POLY_START;
            end
        end
        ST_LOAD_POLY_START: begin
            i_p0_id = `POLY_2;
            i_p0_idx = ctr_poly;
            i_p0_en = 1;
            next_state = ST_LOAD_POLY_WAIT_DONE;
        end
        ST_LOAD_POLY_WAIT_DONE: begin
            i_p0_id = `POLY_2;
            i_p0_idx = ctr_poly;            
            ntt_i_valid = i_p0_valid;
            if (i_p0_done) begin
                if (ctr_poly < (L - 1)) begin
                    next_state = ST_LOAD_POLY_START;
                    ctr_poly_inc = 1;
                end
                else begin
                    next_state = ST_LOAD_IPSI_START;
                    ctr_poly_rst = 1;
                end
            end
        end
        ST_LOAD_IPSI_START: begin
            i_p0_id = `PSI_INV;
            i_p0_idx = ctr_L_;
            i_p0_en = 1;
            next_state = ST_LOAD_IPSI_WAIT_DONE;
        end
        ST_LOAD_IPSI_WAIT_DONE: begin
            i_p0_id = `PSI_INV;
            i_p0_idx = ctr_L_;
            psi_i_valid = i_p0_valid;
            if (i_p0_done) begin
                next_state = ST_INTT_READY;
            end
        end
        ST_INTT_READY: begin
            intt_ready = 1'b1;
            next_state = ST_IDLE;
            if (ctr_L == (L)) begin
                ctr_L_rst = 1;
            end
            else begin
                ctr_L_inc = 1;
            end
        end
    endcase
end


endmodule