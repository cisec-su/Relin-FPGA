module accumulator_loop
   #(
        parameter LOGK         = 10,   // log2(K), determines the size of the accumulator block
        parameter LOGQ         = 64,   // Word size for coefficients
        parameter LOGQH        = 47,   // Modulus size for modular arithmetic
        parameter FF_ADD       = 0 ,   // Number of flip-flops in the addition pipeline
        parameter VALID_SINGLE = 1 ,   // Single cycle valid signal
        parameter TP           = 32    // Number of coefficients processed in parallel
    )
    (
        input              clk       , // Clock signal
        input              rst       , // Reset signal
        input              ren       , // Read enable signal for accumulation
        input              wen       , // Write enable signal for accumulation
        input              load_q    , // Signal to load modulus value
        input  [LOGQH-1:0] qH        , // Modulus value for modular arithmetic
        output             o_valid   , // Indicates the first valid output cycle
        output reg         done      , // Signals that the operation (ren or wen) is complete. Ready for new command (ren or wen) at this cc
        output reg         busy      , // Indicates that the module is currently busy
        input  [LOGQ -1:0] A [TP-1:0], // Input array of coefficients
        output [LOGQ -1:0] C [TP-1:0]  // Output array of accumulated coefficients
    );

///////////////////////////// Parameters ////////////////////////////////

localparam K = (1 << LOGK);

/////////////////////////////////////////////////////////////////////////




///////////////////////// State Declarations ////////////////////////////
typedef enum logic [2:0] {
    ST_IDLE              = 3'b001,
    ST_READ              = 3'b010,
    ST_WRITE             = 3'b100
} state_t;
/////////////////////////////////////////////////////////////////////////




///////////////////////// Signal Declarations ///////////////////////////

wire [LOGK-1:0] addr;

wire o_valid_int;
generate 
    if (VALID_SINGLE) begin : GEN_O_VALID_REG
        reg o_valid;
    end
endgenerate
reg o_valid_q;

reg done_set;
reg ren_int, wen_int;

reg ctr_inc;

state_t state, next_state;

/////////////////////////////////////////////////////////////////////////




/////////////////////////////////////////////////////////////////////////



accumulator #(
    .LOGK   (LOGK),
    .LOGQ   (LOGQ),
    .LOGQH  (LOGQH),
    .FF_IN  (1),
    .FF_ADD (FF_ADD),
    .TP     (TP)
) accumulator_inst (
    .clk     (clk),
    .rst     (rst),
    .addr    (addr),
    .ren     (ren_int),
    .wen     (wen_int),
    .load_q  (load_q),
    .qH      (qH),
    .o_valid (o_valid_int),
    .A       (A),
    .C       (C)
);


counter #(
    .WIDTH(LOGK)
) ctr_inst (
    .clk   (clk       ),
    .rst   (rst       ),
    .inc   (ctr_inc   ),
    .ctr   (addr      )
);


generate
    if (VALID_SINGLE) begin
        assign o_valid = o_valid_int & ~GEN_O_VALID_REG.o_valid;
    end
    else begin
        assign o_valid = o_valid_int;
    end
endgenerate


generate
    if (VALID_SINGLE) begin
        always @(posedge clk) begin
            if (rst) begin
                GEN_O_VALID_REG.o_valid <= 0;
            end
            else begin
                GEN_O_VALID_REG.o_valid <= o_valid_int;
            end
        end
    end
endgenerate


always @(posedge clk) begin
    if (rst) begin
        done <= 0;
    end
    else if (done_set) begin
        done <= 1;
    end
    else if (done) begin
        done <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;  // Reset to idle state
    end
    else begin
        state <= next_state;
    end
end


// FSM
always @(*) begin
    busy = 0;
    done_set = 0;
    ctr_inc = 0;
    ren_int = 0;
    wen_int = 0;
    next_state = state;

    case (state)
        ST_IDLE: begin
            if (ren) begin
                ctr_inc = 1;
                ren_int = 1;
                next_state = ST_READ;
            end else if (wen) begin
                ctr_inc = 1;
                wen_int = 1;
                next_state = ST_WRITE;
            end
        end
        ST_READ: begin
            busy = 1;
            ren_int = 1;
            if (addr == (K - 1)) begin
                done_set = 1;
                next_state = ST_IDLE;
            end
        end
        ST_WRITE: begin
            busy = 1;
            wen_int = 1;
            if (addr == (K - 1)) begin
                done_set = 1;
                next_state = ST_IDLE;
            end
        end
    endcase
end



/////////////////////////////////////////////////////////////////////////


endmodule
