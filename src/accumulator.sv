module accumulator #(
    parameter LOGK      = 10,   // log2(K), determines the size of the accumulator block
    parameter LOGQ      = 64,   // Word size for coefficients
    parameter LOGQH     = 47,   // Modulus size for modular arithmetic
    parameter FF_ADD    = 0 ,   // Number of flip-flops in the addition pipeline
    parameter TP        = 32    // Number of coefficients processed in parallel
) (
    input              clk       , // Clock signal
    input              rst       , // Reset signal
    input              ren       , // Read enable signal for accumulation
    input              wen       , // Write enable signal for accumulation
    input              load_q    , // Signal to load modulus value
    input  [LOGQH-1:0] qH        , // Modulus value for modular arithmetic
    output reg         o_valid   , // Indicates the first valid output cycle
    output reg         done      , // Signals that the operation (ren or wen) is complete
    output reg         busy      , // Indicates that the module is currently busy
    input  [LOGQ -1:0] A [TP-1:0], // Input array of coefficients
    output [LOGQ -1:0] C [TP-1:0]  // Output array of accumulated coefficients
);

///////////////////////////// Parameters ////////////////////////////////
localparam K        = (1 << LOGK);              // Total accumulation blocks based on LOGK
localparam FF_IN    = 1;                        // Flip-flop for input pipeline stage
localparam FF_OUT   = 1;                        // Flip-flop for output pipeline stage
localparam LAT      = FF_ADD + FF_IN + FF_OUT;  // Total pipeline latency
/////////////////////////////////////////////////////////////////////////

///////////////////////// Type Declarations ///////////////////////////
typedef enum logic [4:0] {
    ST_IDLE              = 5'b00001,
    ST_READ              = 5'b00010,
    ST_WRITE_INIT        = 5'b00100,
    ST_WRITE_LOOP        = 5'b01000,
    ST_WRITE_END         = 5'b10000
} state_t;
/////////////////////////////////////////////////////////////////////////

///////////////////////// Signal Declarations ///////////////////////////
reg  [LOGQH-1:0] qH_int;                  // Stored modulus value
wire [LOGQ-1 :0] modadd_out   [TP-1:0];   // Output of modular addition pipeline
reg  [LOGQ-1 :0] A_q          [TP-1:0];   // Register A

wire [LOGQ-1 :0] bram_out [TP-1:0];       // Output data from BRAM

reg  [LOGK-1:0] read_addr;                  // Counter for read operations
reg  [LOGK-1:0] write_addr;                 // Write address for BRAM
reg start_read, start_write;                // Signals to start read and write operations

reg  done_int;                            // Internal signal for done indication
reg  bram_wen;                            // Write enable for BRAM

state_t state, next_state;                // State machine signals
/////////////////////////////////////////////////////////////////////////

// Output signal assignments
generate
    for (genvar i = 0; i < TP; i++) begin : OUT_GEN
        assign C[i] = bram_out[i];
    end
endgenerate

/////////////////////////////////////////////////////////////////////////

// Modular addition instances
generate
    for (genvar i = 0; i < TP; i++) begin : MODADD_GEN
        modadd #(
            .LOGA  (LOGQ  ), // Input A width
            .LOGB  (LOGQ  ), // Input B width
            .LOGQ  (LOGQ  ), // Output width
            .LOGQH (LOGQH ), // Modulus width
            .FF_IN (0     ), // Input pipeline stage. Done manually, see A_q
            .FF_ADD(FF_ADD), // Addition pipeline stage
            .FF_OUT(FF_OUT)  // Output pipeline stage
        ) mod_adder_inst (
            .clk(clk          ), // Clock signal
            .A  (bram_out[i]  ), // Input from BRAM
            .B  (A_q[i]       ), // Input coefficient array
            .qH (qH_int       ), // Modulus value
            .C  (modadd_out[i])  // Result of modular addition
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : BRAM_GEN
        BRAM #(
            .DSIZE(LOGQ),          // Data size (word size)
            .MSIZE(K),             // Memory size
            .DEPTH(LOGK)           // Address width
        ) bram_inst (
            .clk  (clk          ),   // Clock signal
            .wen  (bram_wen     ),   // Write enable
            .waddr(write_addr   ),   // Write address
            .din  (modadd_out[i]),   // Data input
            .raddr(read_addr    ),   // Read address
            .dout (bram_out[i]  )    // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////


// Load modulus value on reset or load_q
always @(posedge clk) begin
    if (rst) begin
        qH_int <= 0;
    end else if (load_q) begin
        qH_int <= qH;
    end
end


// Register A 
always @(posedge clk) begin
    A_q <= A;
end


// State machine and counters
always @(posedge clk) begin
    if (rst) begin
        write_addr <= 0;
    end
    else if (start_write || (write_addr != 0)) begin
        write_addr <= write_addr + 1;
    end
end


always @(posedge clk) begin
    if (rst) begin
        read_addr <= 0;
    end
    else if (start_read || (read_addr != 0)) begin
        read_addr <= read_addr + 1;
    end
end


// State machine and counters
always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;  // Reset to idle state
    end
    else begin
        state <= next_state;
    end
end



// State machine and counters
always @(*) begin
    next_state  = state;  // Reset to idle state
    o_valid     = 0;       // Reset valid signal
    done        = 0;       // Reset done signal
    busy        = 0;       // Reset done signal
    bram_wen    = 0;       // Disable BRAM writes
    start_write = 0;
    start_read  = 0;
    case (state)
        ST_IDLE: begin
            if (ren) begin
                start_read = 1;
                next_state = ST_READ;
            end else if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
        end
        ST_READ: begin
            busy = 1;
            if (read_addr == 1) begin
                o_valid = 1;
            end
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_IDLE;
            end
        end
        ST_WRITE_INIT: begin
            busy = 1;
            if (read_addr == LAT) begin
                start_write = 1;
                next_state  = ST_WRITE_LOOP;
            end
        end
        ST_WRITE_LOOP: begin
            busy = 1;
            bram_wen    = 1;
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_WRITE_END;
            end
        end
        ST_WRITE_END: begin
            bram_wen  = 1;
            if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
            else if (write_addr == (K - 1)) begin
                next_state = ST_IDLE;
            end
        end
        default: next_state = ST_IDLE;
    endcase
end

/////////////////////////////////////////////////////////////////////////


endmodule
