module accumulator #(
    parameter LOGK      = 10,   // log2(K), determines the size of the accumulator block
    parameter LOGQ      = 64,   // Word size for coefficients
    parameter LOGQH     = 47,   // Modulus size for modular arithmetic
    parameter FF_ADD    = 1 ,   // Number of flip-flops in the addition pipeline
    parameter TP        = 32    // Number of coefficients processed in parallel
) (
    input              clk       , // Clock signal
    input              rst       , // Reset signal
    input              ren       , // Read enable signal for accumulation
    input              wen       , // Write enable signal for accumulation
    input              load_q    , // Signal to load modulus value
    input  [LOGQH-1:0] qH        , // Modulus value for modular arithmetic
    output             o_valid   , // Indicates the first valid output cycle
    output             done      , // Signals that the operation (ren or wen) is complete
    output             busy      , // Indicates that the module is currently busy
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
typedef enum logic [1:0] {
    S_IDLE              = 2'b00,
    S_READ              = 2'b01,
    S_WAIT_FOR_LATENCY  = 2'b10,
    S_WRITE             = 2'b11
} state_t;
/////////////////////////////////////////////////////////////////////////

///////////////////////// Signal Declarations ///////////////////////////
logic [LOGQH-1:0] qH_int;                  // Stored modulus value
logic [LOGQ-1 :0] modadd_out   [TP-1:0];   // Output of modular addition pipeline
logic [LOGQ-1 :0] temp_C       [TP-1:0];   // Temporary storage for output values
logic [LOGQ-1 :0] A_q          [TP-1:0];   // Register A

logic [LOGQ-1 :0] bram_din [TP-1:0];       // Input data for BRAM
logic [LOGQ-1 :0] bram_out [TP-1:0];       // Output data from BRAM

logic [LOGK:0] read_addr;                  // Counter for read operations
logic [LOGK:0] write_addr;                 // Write address for BRAM

logic temp_done;                           // Temporary signal for done indication
logic bram_wen;                            // Write enable for BRAM

state_t state;
/////////////////////////////////////////////////////////////////////////

// Output and status signal assignments
assign busy     = (state == S_IDLE) ? 0 : 1;                // Busy signal based on state
assign o_valid  = (state == S_READ) && (read_addr == 1);    // Valid output flag during read
assign done     = temp_done;                                // Assign temporary done signal to output
assign C        = temp_C;                                   // Assign temporary output to actual output

/////////////////////////////////////////////////////////////////////////

// Modular addition instances
generate
    for (genvar i = 0; i < TP; i++) begin : modadd_instances
        modadd #(
            .LOGA  (LOGQ  ), // Input A width
            .LOGB  (LOGQ  ), // Input B width
            .LOGQ  (LOGQ  ), // Output width
            .LOGQH (LOGQH ), // Modulus width
            .FF_IN (FF_IN ), // Input pipeline stage
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
    for (genvar i = 0; i < TP; i++) begin : bram_instances
        BRAM #(
            .DSIZE(LOGQ),          // Data size (word size)
            .MSIZE(K),             // Memory size
            .DEPTH(LOGK)           // Address width
        ) bram_inst (
            .clk(clk),             // Clock signal
            .wen(bram_wen),        // Write enable
            .waddr(write_addr),    // Write address
            .din(bram_din[i]),     // Data input
            .raddr(read_addr),     // Read address
            .dout(bram_out[i])     // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// Load modulus value on reset or load_q
always @(posedge clk or posedge rst) begin
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
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= S_IDLE;  // Reset to idle state
        temp_done   <= 0;       // Reset done signal
        bram_wen    <= 0;       // Disable BRAM writes

        write_addr  <= 0;       // Reset write counter
        read_addr   <= 0;       // Reset read counter
    end else begin
        temp_done <= 0;         // Done pulse signal
        bram_wen  <= 0;         // Disable BRAM write signal

        case (state)
            S_IDLE: begin
                read_addr   <= 0;
                write_addr  <= 0;

                if (ren) begin
                    state       <= S_READ;
                end else if (wen) begin
                    read_addr   <= 1;
                    state       <= S_WAIT_FOR_LATENCY;
                end
            end

            S_READ: begin
                read_addr <= read_addr + 1;
                if (read_addr == K) begin
                    temp_done   <= 1;
                    state       <= S_IDLE;
                end
            end

            S_WAIT_FOR_LATENCY: begin
                read_addr  <= read_addr + 1;
                if (read_addr == LAT) begin
                    state   <= S_WRITE;
                end
            end

            S_WRITE: begin

                bram_wen    <= 1;
                read_addr   <= read_addr + 1;

                if (bram_wen == 0) begin 
                    write_addr <= 0;
                end else begin 
                    write_addr <= write_addr + 1;
                end 


                if (write_addr == K-1 ) begin
                    bram_wen    <= 0;
                    temp_done   <= 1;       // Indicate completion of write
                    state       <= S_IDLE;  // Return to idle state
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end

generate 
    for (genvar i = 0; i < TP; i++) begin : bram_din_assign
        always @(posedge clk) begin
            bram_din[i] <= modadd_out[i]; // Write modular addition result
            temp_C[i]   <= bram_out[i];
        end 
    end 
endgenerate

/////////////////////////////////////////////////////////////////////////


endmodule
