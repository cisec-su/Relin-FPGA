`timescale 1ns/1ps

module accumulator_tb;

// Parameters
parameter LOGK      = 4;   // log2(K), determines the size of the accumulator array
parameter LOGQ      = 64;  // Word size for coefficients and intermediate values
parameter LOGQH     = 47;  // Modulus size for modular arithmetic
parameter FF_ADD    = 1;   // Number of flip-flops in the addition pipeline
parameter TP        = 10;   // Number of coefficients processed in parallel 

// Testbench signals
reg             clk;              // Clock signal
reg             rst;              // Reset signal
reg             ren;              // Read enable signal for accumulation
reg             wen;              // Write enable signal for accumulation
reg             load_q;           // Signal to load modulus value
reg  [LOGQH-1:0] qH;              // Modulus value
reg  [LOGQ-1:0] A[TP-1:0];        // Input array of coefficients
wire [LOGQ-1:0] C[TP-1:0];        // Output array of accumulated coefficients
wire            o_valid;          // Indicates the first valid output cycle
wire            done;             // Signals that the operation is complete
wire            busy;             // Indicates that the module is currently busy

integer clk_ctr;                  // Clock cycle counter
integer coeff;                    // Coefficient for setting inputs

// DUT instantiation
accumulator #(
    .LOGK(LOGK),                  // log2(K) parameter for accumulator
    .LOGQ(LOGQ),                  // Word size parameter
    .LOGQH(LOGQH),                // Modulus size parameter
    .FF_ADD(FF_ADD),              // Flip-flop addition stage parameter
    .TP(TP)                       // Coefficient throughput parameter
) dut (
    .clk(clk),                    // Clock input
    .rst(rst),                    // Reset input
    .ren(ren),                    // Read enable input
    .wen(wen),                    // Write enable input
    .load_q(load_q),              // Load modulus input
    .qH(qH),                      // Modulus value input
    .o_valid(o_valid),            // Valid output indicator
    .done(done),                  // Done signal
    .busy(busy),                  // Busy indicator
    .A(A),                        // Input coefficient array
    .C(C)                         // Output coefficient array
);

// Clock generation
initial begin
    clk <= 1;                      // Initialize clock signal
    forever #5 clk <= ~clk;        // Generate a clock with 10 ns period
end

// Reset logic
initial begin
    rst <= 1;                      // Assert reset signal
    repeat (10) @(posedge clk);   // Hold reset for 10 clock cycles
    rst <= 0;                      // Deassert reset signal
end

// Clock cycle counter
always @(posedge clk or posedge rst) begin
    if (rst) begin 
        clk_ctr <= 0;             // Reset clock cycle counter
    end else begin 
        clk_ctr <= clk_ctr + 1;   // Increment counter on each clock edge
    end
end

// Task to initialize inputs
task initialize_inputs;
    begin
        ren <= 0;                  // Disable read enable
        wen <= 0;                  // Disable write enable
        load_q <= 0;               // Disable load modulus signal
        qH <= 0;                   // Initialize modulus to 0
    end
endtask

// Task to set coefficients
task set_coefficients(input [LOGQ-1:0] base_value);
    int random_in_range;          // Local variable for random values
    begin
        for (integer i = 0; i < TP; i = i + 1) begin
            A[i] <= (base_value + i); // Set coefficients sequentially
        end
    end
endtask

// Task to assert read enable for one clock cycle
task assert_ren;
    begin
        @(posedge clk);
        ren <= 1;                  // Assert read enable
        @(posedge clk);
        ren <= 0;                  // Deassert read enable
        wait(done);               // Wait until done signal is asserted
        @(posedge clk);           // Wait for one more clock cycle
    end
endtask

// Task to assert write enable for one clock cycle
task assert_wen(input logic [LOGQ-1:0] coeff_in);
    begin
        coeff <= coeff_in;        // Initialize coefficient value
        @(posedge clk);
        set_coefficients(coeff);  // Set initial coefficients
        
        // Assert write enable to start the write operation
        @(posedge clk);
        wen <= 1;                 // Assert write enable
        coeff <= coeff + 1;       // Increment coefficient value
        @(posedge clk);
        wen <= 0;                 // Deassert write enable

        // Wait for done signal while updating coefficients
        while (!done) begin
            coeff <= coeff + 1;   // Increment coefficient
            set_coefficients(coeff); // Update coefficients
            @(posedge clk);
        end

        // Reset coefficient value after operation
        coeff <= 0;
        @(posedge clk);
    end
endtask

// Task to load modulus value
task t_load_q(input logic [LOGQH-1:0] qH_in);
    begin
        load_q <= 1;               // Assert load modulus signal
        qH <= qH_in;              // Set modulus value
        @(posedge clk);
        load_q <= 0;               // Deassert load modulus signal
    end
endtask

// Testbench logic
initial begin
    // Initialize inputs
    initialize_inputs;
    // Wait for reset release
    @(negedge rst);

    // Load modulus value
    t_load_q(255);
    t_load_q(255);

    // Wait for one clock cycle
    @(posedge clk);

    // Perform write operations with coefficients
    assert_wen(10);
    assert_wen(100);

    // Perform read operations
    assert_ren();
    assert_ren();
    assert_wen(1000);
    assert_wen(100);
    assert_ren();
    assert_ren();

    // End simulation
end

endmodule
