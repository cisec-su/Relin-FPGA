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
localparam K        = (1 << LOGK);  // Total accumulation blocks based on LOGK
localparam FF_IN    = 1;            // Flip-flop for input pipeline stage
localparam FF_OUT   = 1;            // Flip-flop for output pipeline stage
localparam LAT      = FF_ADD + FF_IN + FF_OUT - 1; // Total pipeline latency

/////////////////////////////////////////////////////////////////////////


///////////////////////// Signal Declarations ///////////////////////////
reg [LOGQ-1:0] acc   [K-1:0][TP-1:0];   // Internal 2D array for accumulator
reg [LOGQ-1:0] modadd_out   [TP-1:0];   // Output of modular addition pipeline
reg [LOGQH-1:0] qH_int;                 // Stored modulus value
logic [LOGQ-1:0] temp_C [TP-1:0];       // Temporary storage for output values
logic temp_done;                        // Temporary signal for done indication

// State declaration
typedef enum logic [1:0] {
    S_IDLE              = 2'b00, 
    S_READ              = 2'b01, 
    S_WAIT_FOR_LATENCY  = 2'b10,  
    S_WRITE             = 2'b11  
} state_t;

state_t state;

// Counter declarations
integer write_ctr; // Counter for write operations
integer read_ctr;  // Counter for read operations
integer id_ctr;    // Intermediate counter for indexing

/////////////////////////////////////////////////////////////////////////

// Output and status signal assignments
assign busy     = (state == S_IDLE) ? 0 : 1;            // Busy signal based on state
assign id_ctr   = (write_ctr < K) ? write_ctr : TP;     // Counter for modular addition indexing
assign o_valid  = (state == S_READ) && (read_ctr == 1); // Valid output flag during read
assign C        = temp_C;                               // Assign temporary output to actual output
assign done     = temp_done;                            // Assign temporary done signal to output

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
            .clk(clk            ), // Clock signal
            .A  (acc[id_ctr][i] ), // Input from accumulator array
            .B  (A[i]           ), // Input coefficient array
            .qH (qH_int         ), // Modulus value
            .C  (modadd_out[i]  )  // Result of modular addition
        );
    end
endgenerate


/////////////////////////// Sequential Logic ////////////////////////////
// Load modulus value on reset or when load_q is asserted
always @(posedge clk or posedge rst) begin
    if (rst) begin
        qH_int <= {LOGQH{1'b0}}; // Reset modulus value
    end else if (load_q) begin
        qH_int <= qH; // Load new modulus value
    end
end

// Initialize and update the accumulator array
generate
    for (genvar i = 0; i < K; i++) begin : gen_acc_init
        for (genvar j = 0; j < TP; j++) begin : gen_acc_update
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    acc[i][j] <= {LOGQ{1'b0}}; // Reset accumulator values
                end else if (load_q) begin 
                    acc[i][j] <= {LOGQ{1'b0}}; // Reset accumulator on load
                end else if (state == S_WRITE && (write_ctr - LAT) == i) begin
                    acc[i][j] <= modadd_out[j]; // Update accumulator with modular addition result
                end
            end
        end
    end
endgenerate

// Update the output values during the read state
generate
    for (genvar i = 0; i < TP; i++) begin : gen_C
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                temp_C[i] <= {LOGQ{1'b0}}; // Reset output values
            end else if (state == S_READ) begin
                temp_C[i] <= acc[read_ctr][i]; // Load output from accumulator
            end
        end
    end
endgenerate

////////////////////////////////////////////////////////////////

// State machine and counters
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= S_IDLE;  // Reset to idle state
        write_ctr   <= 0;       // Reset write counter
        read_ctr    <= 0;       // Reset read counter
        temp_done   <= 0;       // Reset temporary done signal
    end else begin
        temp_done <= 0; // Reset temporary done signal by default
        case (state)
            S_IDLE: begin
                write_ctr   <= 0; // Reset write counter
                read_ctr    <= 0; // Reset read counter
                if (ren) begin
                    state <= S_READ;  
                end else if (wen) begin
                    state <= S_WAIT_FOR_LATENCY;  
                end
            end

            S_READ: begin
                read_ctr <= read_ctr + 1; // Increment read counter
                if (read_ctr == K) begin
                    temp_done   <= 1; // Indicate completion of read
                    state       <= S_IDLE; // Return to idle state
                end
            end

            S_WAIT_FOR_LATENCY: begin
                write_ctr <= write_ctr + 1; // Increment write counter
                if (write_ctr == LAT - 1) begin
                    state   <= S_WRITE; // Transition to write state
                end
            end

            S_WRITE: begin
                write_ctr <= write_ctr + 1; // Increment write counter
                if (write_ctr == LAT + K - 1) begin
                    temp_done   <= 1; // Indicate completion of write
                    state       <= S_IDLE; // Return to idle state
                end
            end

            default: begin
                state <= S_IDLE; // Default to idle state
            end
        endcase
    end
end

endmodule

