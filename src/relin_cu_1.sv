module relin_cu_1
   #(   
        parameter L = 30 // loads L + 1 polynomials
    )
    (
        input              clk          ,
        input              rst          ,
        input              start        ,
        input              load_ntt     ,
        input              load_intt    ,
        input              i_psi_ready  ,
        input              i_psi_done   ,
        input              i_poly_ready ,
        input              i_poly_done  ,
        output             i_psi_id     ,
        output reg         i_psi_en     ,
        output reg         i_psi_inv    ,
        output             i_poly_id    ,
        output reg         i_poly_en    ,
        output reg         intt         ,
        output reg         load_q       , // todo: fix this
        output reg         feed_intt    ,
        output reg         busy
    );


localparam LOGL = $rtoi($ceil($clog2(L)));


typedef enum reg[10:0] {
    ST_IDLE                      = 11'b00000000001,
    ST_LOAD_Q                    = 11'b00000000010,
    ST_LOAD_PSI_START            = 11'b00000000100,
    ST_LOAD_PSI_WAIT_DONE        = 11'b00000001000,
    ST_LOAD_POLY_START           = 11'b00000010000,
    ST_LOAD_POLY_WAIT_DONE       = 11'b00000100000,
    ST_LOAD_IPSI_START           = 11'b00001000000,
    ST_LOAD_IPSI_WAIT_DONE       = 11'b00010000000,
    ST_READY                     = 11'b00100000000
} t_state;

(* fsm_encoding = "none" *) t_state state;
t_state next_state;


reg [LOGL-1:0] ctr_L;
reg ctr_L_inc;
reg ctr_L_rst;

reg [LOGL-1:0] ctr_poly;
reg ctr_poly_inc;
reg ctr_poly_rst;

reg intt_set, intt_clr;

always @(posedge clk) begin
    if (rst) begin
        ctr_poly <= 0;
    end
    else if (ctr_poly_inc) begin
        ctr_poly <= ctr_poly + 1;
    end
    else if (ctr_poly_rst) begin
        ctr_poly <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        ctr_L <= 0;
    end
    else if (ctr_L_inc) begin
        ctr_L <= ctr_L + 1;
    end
    else if (ctr_L_rst) begin
        ctr_L <= 0;
    end
end


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

assign i_psi_id = ctr_L;
assign i_poly_id = ctr_poly;


always @(*) begin

    next_state = state;
    busy = 1'b0;
    load_q = 1'b0;
    i_psi_en = 1'b0;
    i_psi_inv = 1'b0;
    i_poly_en = 1'b0;
    intt_set = 1'b0;
    intt_clr = 1'b0;
    feed_intt = 1'b0;
    ctr_poly_inc = 1'b0;
    ctr_poly_rst = 1'b0;
    ctr_L_inc = 1'b0;
    ctr_L_rst = 1'b0;


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
            if (load_intt) begin
                next_state = ST_LOAD_IPSI_START;
                intt_set = 1;
            end
            else if (load_ntt) begin
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
            if (i_psi_ready) begin
                i_psi_en = 1;
                next_state = ST_LOAD_PSI_WAIT_DONE;
            end
        end
        ST_LOAD_PSI_WAIT_DONE: begin
            busy = 1;
            if (i_psi_done) begin
                next_state = ST_LOAD_POLY_START;
            end
        end
        ST_LOAD_POLY_START: begin
            busy = 1;
            if (i_poly_ready) begin
                i_poly_en = 1;
                next_state = ST_LOAD_POLY_WAIT_DONE;
            end
        end
        ST_LOAD_POLY_WAIT_DONE: begin
            busy = 1;
            if (i_poly_done) begin
                if (ctr_poly < L) begin
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
            i_psi_inv = 1;
            if (i_psi_ready) begin
                i_psi_en = 1;
                next_state = ST_LOAD_IPSI_WAIT_DONE;
            end
        end
        ST_LOAD_IPSI_WAIT_DONE: begin
            busy = 1;
            i_psi_inv = 1;
            if (i_psi_done) begin // check i_psi_ready at this cc
                feed_intt = 1;
                if (ctr_L < (L - 1)) begin
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