module accumulator #(
    parameter LOGK      = 2 ,   // log2(K)
    parameter LOGQ      = 64,   // Word size
    parameter LOGQH     = 47,   // Word size
    parameter FF_ADD    = 1 ,   // Flip-Flop for Addition
    parameter TP        = 32    // Coefficient throughput
) (
    input              clk       , // Clock signal
    input              rst       , // Reset signal
    input              en        , // Enable signal for accumulation
    input              load_q    , // Signal to load modulus value
    input  [LOGK -1:0] id        , // Index arriving at the input
    input  [LOGQH-1:0] qH        , // Modulus value for modular arithmetic
    input  [LOGQ -1:0] A [TP-1:0], // Packed array for input values
    output reg [LOGQ -1:0] C [TP-1:0]  // Packed array for accumulator values
);

///////////////////////////// parameters ////////////////////////////////

localparam K        = 1 << LOGK;
localparam FF_IN    = 1;
localparam FF_OUT   = 1;
localparam LAT      = FF_ADD + FF_IN + FF_OUT + 1; 

/////////////////////////////////////////////////////////////////////////


///////////////////////// Signals Declaration ///////////////////////////
reg [ LOGQ-1:0] acc   [K-1:0][TP-1:0]; // Internal accumulator array
reg [ LOGQ-1:0] modadd_out   [TP-1:0]; // Modular addition pipeline
reg [ LOGQ-1:0] A_q          [TP-1:0]; // Modular addition pipeline
reg [ LOGK-1:0] id_pipeline  [LAT :0]; // Pipeline for id to match computation latency
reg [LOGQH-1:0] qH_int               ; // Modulus value
reg             en_pipeline  [LAT :0]; // Pipeline for enable signal to match computation latency

/////////////////////////////////////////////////////////////////////////


// Modular addition instances
generate
    for (genvar i = 0; i < TP; i++) begin : modadd_instances
        modadd #(
            .LOGA  (LOGQ  ),
            .LOGB  (LOGQ  ),
            .LOGQ  (LOGQ  ),
            .LOGQH (LOGQH ),
            .FF_IN (FF_IN ),
            .FF_ADD(FF_ADD),
            .FF_OUT(FF_OUT)
        ) mod_adder_inst (
            .clk(clk                   ),
            .A  (acc[id_pipeline[0]][i]), // Use the id at the first pipeline stage
            .B  (A_q[i]                ), // Input coefficient
            .qH (qH_int                ), // Modulus values
            .C  (modadd_out[i]         )  // Modular addition result
        );
    end
endgenerate


/////////////////////////// Sequential Logic ////////////////////////////

always @(posedge clk or posedge rst) begin
    if (rst) begin
        qH_int <= {LOGQH{1'b0}};
    end else if (load_q) begin
        qH_int <= qH;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (int i = 0; i < TP; i++) begin
            A_q[i] <= {LOGQ{1'b0}};
        end
    end else if (en) begin
        for (int i = 0; i < TP; i++) begin
            A_q[i] <= A[i];
        end
    end
end

// id_pipeline
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (int i = 0; i < LAT; i++) begin
            id_pipeline[i] <= {LOGK{1'b0}};
            en_pipeline[i] <= {1'b0};
        end
    end else begin
        id_pipeline[0] <= id;
        en_pipeline[0] <= en;
        for (int i = 1; i <= LAT; i++) begin
            id_pipeline[i] <= id_pipeline[i - 1];
            en_pipeline[i] <= en_pipeline[i - 1];
        end
    end
end


// Reset and accumulation logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all accumulators and pipeline stages
        for (int i = 0; i < K; i++) begin
            for (int j = 0; j < TP; j++) begin
                acc[i][j] <= {LOGQ{1'b0}};
            end
        end

        for (int i = 0; i < TP; i++) begin
            C[i] <= {LOGQ{1'b0}};
        end

    end else if(load_q) begin
        // Load modulus and reset accumulators
        for (int i = 0; i < K; i++) begin
            for (int j = 0; j < TP; j++) begin
                acc[i][j] <= {LOGQ{1'b0}};
            end
        end
    end else begin
        // Perform modular accumulation
        if (en_pipeline[LAT]) begin
            for (int i = 0; i < TP; i++) begin
                acc[id_pipeline[LAT]][i] <= modadd_out[i];
                C[i] <= modadd_out[i];
            end
        end
    end
end

// Drive the outputs
//generate
//    for (genvar i=0; i < TP; i++) begin : output_assignment
//        assign C[i] = acc[id_pipeline[LAT-1]][i];  // Output uses the pipelined id
//    end
//endgenerate

endmodule
