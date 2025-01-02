`timescale 1ns/1ps

module accumulator_tb;

    // Parameters
    parameter LOGQ  = 64;   // Word size
    parameter TP    = 32;   // Coefficient throughput
    parameter LOGK  = 2;    // log2(K)

    // Testbench signals
    reg                   clk;
    reg                   rst;
    reg                   en;
    reg                   load_q;
    reg  [LOGK-1:0]       id;
    reg  [LOGQ-1:0]   A[TP-1:0];
    reg  [LOGQ-1:0]      qH;
    wire [LOGQ-1:0]   C[TP-1:0];

    integer clk_ctr;

    // DUT instantiation
    accumulator #(
        .LOGQ(LOGQ), 
        .TP(TP),
        .LOGK(LOGK))
    dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .load_q(load_q),
        .id(id),
        .A(A),
        .qH(qH),
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
            qH       = 0;   // Modulus value initialized to 0
        end
    endtask

    task set_coefficients(input [LOGQ-1:0] base_value);
        begin
            for (i = 0; i < TP; i = i + 1) begin
                A[i] = base_value; // coefficients
            end
        end
    endtask

    task print_accumulators;
        begin
            for (i = 0; i < TP; i = i + 1) begin
                $display("C[%0d] = %h", i, C[i*LOGQ +: LOGQ]);
            end
        end
    endtask
    
    // Reset and clock counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_ctr <= 0;  // Reset the clock counter
        end else begin
            clk_ctr <= clk_ctr + 1;  // Increment on every clock edge
        end
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id = 0;
        end else if (en) begin
            id = (id + 1) % (1<<LOGK);
        end
    end

    // Testbench logic
    initial begin
        set_coefficients(0);
        initialize_inputs; // Initialize inputs
        wait(rst==0);
        
        qH = 64'h0000_0000_0100; // Example modulus
        repeat(1) @(posedge clk); 

        en = 1;
        load_q = 1;  // Test load_q functionality (reset accumulators)
        repeat(1) @(posedge clk); 
        load_q = 0; // Deassert load_q 

        // Set coefficients for accumulation
        set_coefficients(1);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1; repeat(10) @(posedge clk);
        en = 1; repeat(500) @(posedge clk);
        en = 0; repeat(5) @(posedge clk);
        en = 1; repeat(5) @(posedge clk);
        en = 0; repeat(5) @(posedge clk);
        en = 1; repeat(5) @(posedge clk);
        en = 0; repeat(5) @(posedge clk);
        en = 1; repeat(5) @(posedge clk);
 
 
        // Enable accumulation and process coefficients
        repeat(100) @(posedge clk); // Wait one clock cycle

        // Print accumulated values
        $display("Accumulated values:");
        print_accumulators();

        // Change coefficients and test further accumulation
        set_coefficients(20);
        repeat(5) @(posedge clk); // Wait one clock cycle

        $display("Accumulated values after second round:");
        print_accumulators();

        ////////////////////////////////////////////////////////////////
        //id = 1;   // Index of Accumulator
        en = 0;
        set_coefficients(2);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(50);
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 0;
        ////////////////////////////////////////////////////////////////
        //id = 2;   // Index of Accumulator
        en = 0;
        set_coefficients(3);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(40);
        repeat(5) @(posedge clk); // Wait one clock cycle
        en = 0;
        ////////////////////////////////////////////////////////////////
        //id = 1;   // Index of Accumulator
        en = 0;
        set_coefficients(1);
        repeat(1) @(posedge clk); // Wait one clock cycle
        en = 1;
        repeat(50) @(posedge clk); // Wait one clock 
        set_coefficients(4);
        repeat(5) @(posedge clk); // Wait one clock cycle   
        en = 0;
        ////////////////////////////////////////////////////////////////
        //id = 3;   // Index of Accumulator
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
