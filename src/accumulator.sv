module accumulator #(
    parameter WIDTH = 64,  // Word size
    parameter TP    = 32,   // Coefficient throughput
    parameter K     = 4,   // Number of internal accumulators 
    parameter LOGK  = 2    // log2(K)
) (
    input                     clk,     // Clock signal
    input                     rst,     // Reset signal
    input                     en,      // Enable signal for accumulation
    input                     load_q,  // Signal to load modulus value
    input      [    LOGK-1:0] id,      // Index
    input      [   WIDTH-1:0] q,       // Modulus value for modular arithmetic
    input      [TP*WIDTH-1:0] A,       // Unpacked array for input values
    output reg [TP*WIDTH-1:0] C        // Unpacked array for accumulator values
);

    reg  [WIDTH-1:0] acc[K-1:0][TP-1:0];         // Internal accumulator array
    reg  [WIDTH-1:0] current_q;                  // Modulus value
    wire [WIDTH-1:0] mod_add_result[TP-1:0];     // Intermediate wires for modular addition results
    
    genvar i; 
    generate // Instantiate the modular adders for each coefficient
        for (i = 0; i < TP; i = i + 1) begin
            modadd #(
                .LOGA(WIDTH),
                .LOGB(WIDTH),
                .LOGQ(WIDTH),
                .LOGQH(WIDTH),
                .FF_IN(1),
                .FF_ADD(1),
                .FF_OUT(1)
            ) mod_adder_inst (
                .clk(clk),
                .A(acc[id][i]),         // Current accumulated value
                .B(A[i*WIDTH+:WIDTH]),  // Coefficient from unpacked array
                .qH(current_q),          // Modulus value
                .C(mod_add_result[i])   // Modular addition result
            );
        end
    endgenerate

    integer t; // General purpose variable  
    integer j; // General purpose variable

    // Sequential logic for accumulation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all accumulators
            for (t = 0; t < K; t = t + 1) begin
                for (j = 0; j < TP; j = j + 1) begin
                    acc[t][j] <= {WIDTH{1'b0}};
                end
            end
            current_q <= {WIDTH{1'b0}}; 
        end else if (en) begin
            if (load_q) begin
                // Load modulus and reset all accumulators 
                for (t = 0; t < K; t = t + 1) begin
                    for (j = 0; j < TP; j = j + 1) begin
                        acc[t][j] <= {WIDTH{1'b0}};
                    end
                end
                current_q <= q; // Load the modulus
            end else begin
                // Perform modular accumulation
                for (j = 0; j < TP; j = j + 1) begin
                    acc[id][j] <= mod_add_result[j];
                end
            end
        end
    end

    // Update the output array
    always @(*) begin
        for (j = 0; j < TP; j = j + 1) begin
            C[j*WIDTH+:WIDTH] = acc[id][j];
        end
    end

endmodule
