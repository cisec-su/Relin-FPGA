module accumulator 
   #(
        parameter LOGK      = 10,   // log2(K), determines the size of the accumulator block
        parameter LOGQ      = 64,   // Word size for coefficients
        parameter LOGQH     = 47,   // Modulus size for modular arithmetic
        parameter FF_IN     = 1 ,   // Place flip-flops in the input pipeline
        parameter FF_ADD    = 0 ,   // Place flip-flops in the addition pipeline
        parameter TP        = 32    // Number of coefficients processed in parallel
    )
    (
        input              clk       , // Clock signal
        input              rst       , // Reset signal
        input  [LOGK -1:0] addr      , // Address signal for BRAM
        input              ren       , // Read enable signal for accumulation
        input              wen       , // Write enable signal for accumulation
        input              load_q    , // Signal to load modulus value
        input  [LOGQH-1:0] qH        , // Modulus value for modular arithmetic
        output             o_valid   , // Indicates C is valid
        input  [LOGQ -1:0] A [TP-1:0], // Input array of coefficients
        output [LOGQ -1:0] C [TP-1:0]  // Output array of accumulated coefficients
    );

///////////////////////////// Parameters ////////////////////////////////

`include "modadd.svh"

localparam K         = (1 << LOGK); // Total accumulation blocks based on LOGK
localparam FF_OUT    = 1;           // Flip-flop for output pipeline stage
localparam LAT_READ  = 1 + FF_IN;   // Read Latency
localparam modadd_params_t params = {LOGQ, LOGQ, LOGQ, LOGQH, 0, FF_ADD, FF_OUT};
localparam LAT_WRITE = FF_IN + 1 + modadd_lat(params) + 1; // Write Latency. + 1 for read, + 1 for write

/////////////////////////////////////////////////////////////////////////





///////////////////////// Signal Declarations ///////////////////////////

reg  [LOGQH-1:0] qH_int;
wire load_q_d;

wire ren_mx;

wire wen_d1;
wire wen_d2;

wire [LOGK-1:0] addr_d1;
wire [LOGK-1:0] addr_d2;

wire [LOGQ -1:0] A_d [TP-1:0];

wire [LOGQ -1:0] modadd_out [TP-1:0];

/////////////////////////////////////////////////////////////////////////




///////////////////// Pipeline Steps ////////////////////////////////////

shift_reg_arr #(
    .SHIFT (FF_IN + 1),
    .WIDTH (LOGQ     ),
    .RST_EN(0        )
) shift_reg_A (
    .clk    (clk),
    .i_data (A  ),
    .o_data (A_d)
);


shift_reg #(
    .SHIFT (FF_IN),
    .WIDTH (LOGK ),
    .RST_EN(0    )
) shift_reg_addr_1 (
    .clk    (clk ),
    .i_data (addr),
    .o_data (addr_d1)
);


shift_reg #(
    .SHIFT (LAT_WRITE - 1 - FF_IN),
    .WIDTH (LOGK                 ),
    .RST_EN(0                    )
) shift_reg_addr_2 (
    .clk    (clk   ),
    .i_data (addr_d1),
    .o_data (addr_d2)
);


shift_reg #(
    .SHIFT (LAT_WRITE - 1),
    .WIDTH (1            ),
    .RST_EN(1            )
) shift_reg_wen (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (wen   ),
    .o_data (wen_d )
);


shift_reg #(
    .SHIFT (LAT_READ),
    .WIDTH (1    ),
    .RST_EN(1    )
) shift_reg_ren (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (ren    ),
    .o_data (o_valid)
);


/////////////////////////////////////////////////////////////////////////




///////////////////// Modular addition instances ////////////////////////

generate
    for (genvar i = 0; i < TP; i++) begin : MODADD_GEN
        modadd #(
            .LOGA  (LOGQ  ),
            .LOGB  (LOGQ  ),
            .LOGQ  (LOGQ  ),
            .LOGQH (LOGQH ),
            .FF_IN (0     ),
            .FF_ADD(FF_ADD),
            .FF_OUT(FF_OUT)
        ) mod_adder_inst (
            .clk(clk          ),
            .A  (C[i]         ),
            .B  (A_d[i]       ),
            .qH (qH_int       ),
            .C  (modadd_out[i])
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////




///////////////////// BRAM instances ////////////////////////////////////

generate
    for (genvar i = 0; i < TP; i++) begin : BRAM_GEN
        bram #(
            .WIDTH (LOGQ),
            .LENGTH(K   )
        ) bram_inst (
            .clk  (clk          ),
            .wen  (wen_d        ),
            .waddr(addr_d2      ),
            .din  (modadd_out[i]),
            .raddr(addr_d1      ),
            .dout (C[i]         )
        );
    end
endgenerate

/////////////////////////////////////////////////////////////////////////



///////////////////////////////// store qH //////////////////////////////

always @(posedge clk) begin
    if (load_q) begin
        qH_int <= qH;
    end
end

/////////////////////////////////////////////////////////////////////////



endmodule
