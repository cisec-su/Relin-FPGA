/*
    Computes tensor product
    Input polynomials (p00,p01) and (p10,p11)  
    Notation:
    p00 --> A 
    p01 --> B
    
    p10 --> C
    p11 --> D
    
    Output polynomial (p20, p21, p22)
    p20 = (p10 * p00)                   = AB 
    p21 = (p11 * p00) + (p10 * p01)     = AD + BC
    p22 = (p11 * p01)                   = BD
*/

`include "modmul_wlm.svh"

module tensor_product #(
    parameter LOGN      = 10,   // log2(N), determines the number of coefficients one poly have
    parameter LOGQ      = 64,   // Word size for coefficients
    parameter LOGQH     = 47,   // Modulus size for modular arithmetic
    parameter TP        = 32    // Number of coefficients processed in parallel
) (
    input              clk            , // Clock signal
    input              rst            , // Reset signal
    input              load_q         , // Signal to load modulus value
    input  [LOGQH-1:0] qH             , // Modulus value for modular arithmetic
    input              i_valid        , // Valid signal for input polynomial (Pulse)
    input  [LOGQ -1:0] i_poly [0:TP-1], // Input array of coefficients for the input polynomial
    output             o_valid        , // Indicates the first valid output cycle
    output             o_done         , // Indicates completion of polynomial sending operation
    output             o_busy         , // Indicates that the module is currently busy
    output       [1:0] o_poly_id      , // ID of output polynomial
    output [LOGQ -1:0] o_poly[0:TP-1]  // Input array of coefficients for the output polynomial
);

///////////////////////////// Parameters ////////////////////////////////
localparam N        = (1 << LOGN); // number of coefficients one poly have

localparam FF_ADD   = 1; 
localparam FF_IN    = 1; 
localparam FF_MUL   = 1;
localparam FF_SUM   = 0;
localparam FF_SUB   = 0;
localparam FF_OUT   = 1;
localparam USE_CSA  = 1;
localparam FF_CSA   = 1;
localparam MORE_DSP = 1;
localparam NON_STD  = 0;

localparam W = LOGQ - LOGQH;
localparam modmul_wlm_params_t params = {W, LOGQ, LOGQH, 1, FF_IN, FF_MUL, FF_SUM, FF_SUB, FF_OUT, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
localparam MULT_LAT = modmul_wlm_lat(params);

localparam ADD_LAT  = FF_ADD + FF_IN + FF_OUT;  // Total pipeline latency
/////////////////////////////////////////////////////////////////////////


///////////////////////// Type Declarations ///////////////////////////
typedef enum logic [3:0] {
    ST1_IDLE                  = 4'b0000,
    ST1_SAVE_A                = 4'b0001,
    ST1_SAVE_B                = 4'b0010,
    ST1_SAVE_C_AND_MULT_AC    = 4'b0011,
    ST1_SAVE_D_MULT_AD_COPY_B = 4'b0100,
    
    ST2_IDLE                  = 4'b0101,
    ST2_MULT_BC_ADD_AD        = 4'b0110, 
    ST2_MULT_BD               = 4'b0111

} state_t;
/////////////////////////////////////////////////////////////////////////


///////////////////////// Signal Declarations ///////////////////////////
logic [LOGQH-1:0] qH_int;   // Stored modulus value

logic [LOGQ -1:0] mult1_in [0:TP-1];
logic [LOGQ -1:0] mult2_in [0:TP-1];
logic [LOGQ -1:0] mult_out [0:TP-1];

logic wen_a;                             
logic [LOGN:0] raddr_a;                  
logic [LOGN:0] waddr_a;               
logic [LOGQ -1:0] din_a  [0:TP-1];
logic [LOGQ -1:0] dout_a [0:TP-1];

logic wen_b;                             
logic [LOGN:0] raddr_b;                  
logic [LOGN:0] waddr_b;               
logic [LOGQ -1:0] din_b  [0:TP-1];
logic [LOGQ -1:0] dout_b [0:TP-1];

logic wen_c;                             
logic [LOGN:0] raddr_c;                  
logic [LOGN:0] waddr_c;               
logic [LOGQ -1:0] din_c  [0:TP-1];
logic [LOGQ -1:0] dout_c [0:TP-1];

logic wen_d;                             
logic [LOGN:0] raddr_d;                  
logic [LOGN:0] waddr_d;               
logic [LOGQ -1:0] din_d  [0:TP-1];
logic [LOGQ -1:0] dout_d [0:TP-1];

logic wen_copy_b;                             
logic [LOGN:0] raddr_copy_b;                  
logic [LOGN:0] waddr_copy_b;               
logic [LOGQ -1:0] din_copy_b  [0:TP-1];
logic [LOGQ -1:0] dout_copy_b [0:TP-1];

logic start_ad;                             
logic wen_ad;                             
logic [LOGN:0] raddr_ad;                  
logic [LOGN:0] waddr_ad;               
logic [LOGQ -1:0] din_ad  [0:TP-1];
logic [LOGQ -1:0] dout_ad [0:TP-1];

state_t state1;
state_t state2;

logic done_int;                             
logic valid_int;                             
logic [LOGN:0] counter1;                  
logic [LOGN:0] counter2;                  
logic [LOGN:0] counter3;                  
logic [LOGN:0] counter4;                  
logic [LOGQ-1 :0] add_out [0:TP-1];   // Output of modular addition pipeline

// Load modulus value on reset or load_q
always @(posedge clk or posedge rst) begin
    if (rst) begin
        qH_int <= 0;
    end else if (load_q) begin
        qH_int <= qH;
    end
end

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_A
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_a),            // Write enable
            .waddr(waddr_a),        // Write address
            .din(din_a[i]),         // Data input
            .raddr(raddr_a),        // Read address
            .dout(dout_a[i])        // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_B
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_b),            // Write enable
            .waddr(waddr_b),        // Write address
            .din(din_b[i]),         // Data input
            .raddr(raddr_b),        // Read address
            .dout(dout_b[i])        // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_C
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_c),            // Write enable
            .waddr(waddr_c),        // Write address
            .din(din_c[i]),         // Data input
            .raddr(raddr_c),        // Read address
            .dout(dout_c[i])        // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_D
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_d),            // Write enable
            .waddr(waddr_d),        // Write address
            .din(din_d[i]),         // Data input
            .raddr(raddr_d),        // Read address
            .dout(dout_d[i])        // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_AD
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_ad),            // Write enable
            .waddr(waddr_ad),        // Write address
            .din(din_ad[i]),         // Data input
            .raddr(raddr_ad),        // Read address
            .dout(dout_ad[i])        // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
generate
    for (genvar i = 0; i < TP; i++) begin : bram_copy_B
        BRAM #(
            .DSIZE(LOGQ),           // Data size (word size)
            .MSIZE(N),              // Memory size
            .DEPTH(LOGN)            // Address width
        ) bram_inst (
            .clk(clk),              // Clock signal
            .wen(wen_copy_b),       // Write enable
            .waddr(waddr_copy_b),   // Write address
            .din(din_copy_b[i]),    // Data input
            .raddr(raddr_copy_b),   // Read address
            .dout(dout_copy_b[i])   // Data output
        );
    end
endgenerate
/////////////////////////////////////////////////////////////////////////
 
hadamart #(
    .LOGQ       (LOGQ       ),
    .LOGQH      (LOGQH      ), 
    .FF_IN      (FF_IN      ), 
    .FF_MUL     (FF_MUL     ), 
    .FF_SUM     (FF_SUM     ), 
    .FF_SUB     (FF_SUB     ), 
    .FF_OUT     (FF_OUT     ), 
    .USE_CSA    (USE_CSA    ), 
    .FF_CSA     (FF_CSA     ), 
    .MORE_DSP   (MORE_DSP   ), 
    .NON_STD    (NON_STD    ), 
    .TP         (TP         )
) hadamart_inst (
    .clk(clk          ), //
    .rst(rst          ), //
    .load_q(load_q    ), //
    .A  (mult1_in     ), //  
    .B  (mult2_in     ), //  
    .qH (qH_int       ), // 
    .T  (mult_out     )  //   
);

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
            .A  (dout_ad[i]   ), // Input from BRAM
            .B  (mult_out[i]  ), // Input coefficient array
            .qH (qH_int       ), // Modulus value
            .C  (add_out[i])  // Result of modular addition
        );
    end
endgenerate

assign din_a = i_poly;
assign din_b = i_poly;
assign din_c = i_poly;
assign din_d = i_poly;

assign mult1_in =   (state1 == ST1_SAVE_C_AND_MULT_AC) ? i_poly :
                    (state1 == ST1_SAVE_D_MULT_AD_COPY_B) ? i_poly : 
                    (state2 == ST2_MULT_BC_ADD_AD) ? dout_copy_b : 
                    (state2 == ST2_MULT_BD) ? dout_copy_b : 
                    i_poly;

assign mult2_in =   (state1 == ST1_SAVE_C_AND_MULT_AC) ? dout_a :
                    (state1 == ST1_SAVE_D_MULT_AD_COPY_B) ? dout_a :
                    (state2 == ST2_MULT_BC_ADD_AD) ? dout_c : 
                    (state2 == ST2_MULT_BD) ? dout_d : 
                    i_poly;

assign o_poly   =   (state1 == ST1_SAVE_C_AND_MULT_AC) ? mult_out:
                    (state2 == ST2_MULT_BC_ADD_AD) ? add_out : 
                    (state2 == ST2_MULT_BD) ? mult_out : 
                    mult_out;

assign valid_int=   (state1 == ST1_SAVE_C_AND_MULT_AC) && (waddr_c == MULT_LAT-1) ? 1: 
                    (state2 == ST2_MULT_BC_ADD_AD) && (counter2 == MULT_LAT + ADD_LAT + 1) ? 1: 
                    (state2 == ST2_MULT_BD) && (raddr_d == MULT_LAT) ? 1: 
                    0;

assign o_busy       =   (state1 == ST1_IDLE) ? 0 : 1; // TODO: pipe hale gelecek

assign o_poly_id    =   (state1 == ST1_SAVE_C_AND_MULT_AC) ? 2'b00: 
                        (state2 == ST2_MULT_BC_ADD_AD) ? 2'b01: 
                        (state2 == ST2_MULT_BD) ? 2'b10: 
                        2'b11;

assign o_valid = valid_int;
assign o_done  = done_int;

assign din_copy_b = dout_b;

////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done_int    <= 0;
        counter4    <= 0;
    end else begin
        done_int    <= 0;
        if (valid_int == 1) begin 
            counter4 <= 1;
        end 
        if (counter4 > 0) begin
            counter4 <= counter4 + 1;
        end
        if (counter4 == N) begin
            counter4 <= 0;
            done_int <= 1;
        end
    end
end
////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wen_a    <= 0;       
        waddr_a  <= 0;        
        raddr_a  <= 0;        

        wen_b    <= 0;       
        waddr_b  <= 0;        
        raddr_b  <= 0;        

        wen_c    <= 0;       
        waddr_c  <= 0;       
        raddr_c  <= 0;       

        wen_d    <= 0;       
        waddr_d  <= 0;        

        wen_copy_b    <= 0;       
        waddr_copy_b  <= 0;      

        counter1      <= 0;
        state1   <= ST1_IDLE;    

    end else begin
        wen_a       <= 0;         // Disable BRAM write signal
        wen_b       <= 0;         // Disable BRAM write signal
        wen_c       <= 0;         // Disable BRAM write signal
        wen_d       <= 0;         // Disable BRAM write signal
        wen_copy_b  <= 0;         // Disable BRAM write signal

        case (state1)
            ST1_IDLE: begin
                raddr_a <= 0;
                waddr_a <= 0;
                raddr_b <= 0;
                waddr_b <= 0;
                raddr_c <= 0;
                waddr_c <= 0;
                waddr_d <= 0;
                waddr_copy_b <= 0;
                if (i_valid) begin
                    wen_a   <= 1;        
                    state1  <= ST1_SAVE_A;
                end
            end

            ST1_SAVE_A: begin
                if (waddr_a == N-1 && i_valid == 1) begin
                    wen_b   <= 1;        
                    state1  <= ST1_SAVE_B;
                end else if (waddr_a < N-1 ) begin 
                    wen_a   <= 1;        
                    waddr_a <= waddr_a + 1;
                end
            end

            ST1_SAVE_B: begin
                if (waddr_b == N-1 && i_valid == 1) begin
                    wen_c   <= 1;        
                    state1  <= ST1_SAVE_C_AND_MULT_AC;
                    raddr_a <= 1; 
                end else if (waddr_b < N-1 ) begin 
                    wen_b   <= 1;        
                    waddr_b <= waddr_b + 1;
                end
            end

            ST1_SAVE_C_AND_MULT_AC: begin
                if (waddr_c == N-1 && i_valid == 1) begin
                    wen_d   <= 1;         
                    state1  <= ST1_SAVE_D_MULT_AD_COPY_B;
                    raddr_a <= 1; 
                    raddr_b <= 0;
                end else if (waddr_c < N-1 ) begin 
                    raddr_a <= raddr_a + 1; 
                    wen_c   <= 1;        
                    waddr_c <= waddr_c + 1;
                end
            end

            ST1_SAVE_D_MULT_AD_COPY_B: begin
                if (counter1 == N ) begin
                    counter1    <= 0;
                    state1      <= ST1_IDLE;
                end else if (counter1 < N) begin 
                    counter1 <= counter1 + 1; 
                    if (counter1 < N-1) begin
                        raddr_a <= raddr_a + 1; 
                        wen_d   <= 1;        
                        waddr_d <= counter1 + 1;
                    end
                    raddr_b     <= raddr_b + 1;
                    waddr_copy_b<= raddr_b;
                    wen_copy_b  <= 1;        
                end
            end

            default: state1 <= ST1_IDLE;
        endcase
    end
end
////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter3 <= 0;
        waddr_ad <= 0;
        wen_ad   <= 0;          
        start_ad <= 0;
    end else begin

        wen_ad   <= 0;          

        if (state1 == ST1_SAVE_D_MULT_AD_COPY_B) begin
            start_ad <= 1;
            counter3 <= 1;
        end

        if (counter3 == N + MULT_LAT) begin
            counter3 <= 0;
            start_ad <= 0;
        end
        
        if ((start_ad == 1) && (counter3 < N + MULT_LAT)) begin
            counter3 <= counter3 + 1; 
            if (counter3 > MULT_LAT-1) begin 
                wen_ad   <= 1;          
                waddr_ad <= counter3 - MULT_LAT;
                din_ad   <= mult_out;
            end
        end

    end
end
////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        raddr_ad        <= 0;
        raddr_d         <= 0;
        raddr_copy_b    <= 0;

        counter2        <= 0;
        state2          <= ST2_IDLE; 
    end else begin

        case (state2)

            ST2_IDLE: begin
                counter2     <= 0;
                raddr_d      <= 0;
                raddr_copy_b <= 0;
                if ((state1 == ST1_SAVE_D_MULT_AD_COPY_B) &&  (counter1 == N-1)) begin
                    state2  <= ST2_MULT_BC_ADD_AD;
                end
            end

            ST2_MULT_BC_ADD_AD: begin
                if (counter2 == N+MULT_LAT+ADD_LAT+1) begin
                    state2   <= ST2_MULT_BD;
                    raddr_d      <= 0;
                    raddr_copy_b <= 0;
                end else if (counter2 < N+MULT_LAT+ADD_LAT+1) begin
                    if (counter2 > MULT_LAT - 1) begin 
                        raddr_ad <= counter2 - MULT_LAT; 
                    end         
                    raddr_c      <= counter2;        
                    raddr_copy_b <= counter2; 
                    counter2     <= counter2 + 1;
                end
            end

            ST2_MULT_BD: begin
                if (raddr_d == N + MULT_LAT -1) begin
                    state2  <= ST2_IDLE;
                end else if (raddr_d < N + MULT_LAT -1) begin 
                    raddr_d      <= raddr_d + 1;        
                    raddr_copy_b <= raddr_copy_b + 1;        
                end
            end
            default: state2 <= ST2_IDLE;
        endcase
    end
end
////////////////////////////////////////////////////////////////

endmodule