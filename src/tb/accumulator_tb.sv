`timescale 1ns/1ps

module accumulator_tb;

    // Parameters
    parameter WIDTH = 64; // Word size
    parameter TP = 32;    // Coefficient throughput
    parameter K = 4;      // Number of internal accumulators 
    parameter LOGK = 2;   // log2(K)

    // Testbench signals
    reg                   clk;
    reg                   rst;
    reg                   en;
    reg                   load_q;
    reg  [LOGK-1:0]       id;
    reg  [TP*WIDTH-1:0]   A;
    reg  [WIDTH-1:0]      q;
    wire [TP*WIDTH-1:0]   C;

    // DUT instantiation
    accumulator #(.WIDTH(WIDTH), .TP(TP)) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .load_q(load_q),
        .id(id),
        .A(A),
        .q(q),
        .C(C)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end

    // Reset generation
    initial begin
        rst = 1;        // Apply reset
        repeat (2) @(posedge clk); 
        rst = 0;        // Release reset
        wait(rst==1);   //Wait
    end

    // Tasks for setting inputs and checking outputs
    integer i;

    task initialize_inputs;
        begin
            en      = 0;   // Disable accumulation
            load_q  = 0;   // Load_q is initially deasserted
            id      = 0;   // Index of Accumulator
            q       = 0;   // Modulus value initialized to 0
            A       = 0;   // Input coefficients initialized to 0
        end
    endtask

    task set_coefficients(input [WIDTH-1:0] base_value);
        begin
            for (i = 0; i < TP; i = i + 1) begin
                A[i*WIDTH +: WIDTH] = base_value; // coefficients
            end
        end
    endtask

    task print_accumulators;
        begin
            for (i = 0; i < TP; i = i + 1) begin
                $display("C[%0d] = %h", i, C[i*WIDTH +: WIDTH]);
            end
        end
    endtask
    

    // Testbench logic
    initial begin
        
        initialize_inputs; // Initialize inputs
        wait(rst==0);
        
        q = 64'h0000_0000_0100; // Example modulus
        repeat(1) @(posedge clk); 

        en = 1;
        load_q = 1;  // Test load_q functionality (reset accumulators)
        repeat(1) @(posedge clk); 
        load_q = 0; // Deassert load_q 

        // Set coefficients for accumulation
        set_coefficients(100);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 0;
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 1;
        // Enable accumulation and process coefficients
        repeat(5) @(posedge clk); // Wait one clock cycle

        // Print accumulated values
        $display("Accumulated values:");
        print_accumulators();

        // Change coefficients and test further accumulation
        set_coefficients(20);
        repeat(5) @(posedge clk); // Wait one clock cycle

        $display("Accumulated values after second round:");
        print_accumulators();

        ////////////////////////////////////////////////////////////////
        id = 1;   // Index of Accumulator
        en = 0;
        set_coefficients(2);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(50);
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 0;
        ////////////////////////////////////////////////////////////////
        id = 2;   // Index of Accumulator
        en = 0;
        set_coefficients(3);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(40);
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 0;
        ////////////////////////////////////////////////////////////////
        id = 1;   // Index of Accumulator
        en = 0;
        set_coefficients(1);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(4);
        repeat(5) @(posedge clk); // Wait one clock cycle   
        en = 0;
        ////////////////////////////////////////////////////////////////
        id = 3;   // Index of Accumulator
        en = 0;
        set_coefficients(50);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(4);
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 0;
        ////////////////////////////////////////////////////////////////
        
        
        // End simulation
        $finish;
    end

endmodule
