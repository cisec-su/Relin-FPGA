`include "relin_if.svh"
`include "relin_mem.svh"

// For now, we assume that valid input data is received sequentially starting from clock cycle when i_valid signal = 1.

module relin_mem
   #(   
        parameter LOGQ     = 64,
        parameter LOGN     = 16,
        parameter LOGL     = 5 ,
        parameter ID_WIDTH = 4 ,
        parameter TP       = 32,
        parameter NUM_PSI  = 1 << LOGN
    )
    (
        input                 clk                  ,
        input                 rst                  ,
        // internal memory signals          
        // input port 0
        input                 i_p0_en              ,
        input  [ID_WIDTH-1:0] i_p0_idx             ,
        input  [LOGL-1:0]     i_p0_idy             ,
        output reg            i_p0_ready           , // indicates that the module is ready to accept new command (i_xx_en)
        output                i_p0_valid           ,
        output                i_p0_done            , // indicates the cc for last valid output.
        output [LOGQ-1:0]     i_p0_data    [0:TP-1],
        // input port 1
        input                 i_p1_en              ,
        input  [ID_WIDTH-1:0] i_p1_idx             ,
        input  [LOGL-1:0]     i_p1_idy             ,
        output reg            i_p1_ready           ,
        output                i_p1_valid           ,
        output                i_p1_done            ,
        output [LOGQ-1:0]     i_p1_data    [0:TP-1],
        // input port 2
        input                 i_p2_en              ,
        input  [ID_WIDTH-1:0] i_p2_idx             ,
        input  [LOGL-1:0]     i_p2_idy             ,
        output reg            i_p2_ready           ,
        output                i_p2_valid           ,
        output                i_p2_done            ,
        output [LOGQ-1:0]     i_p2_data    [0:TP-1],
        // output port 0
        input                 o_p3_en              ,
        input  [ID_WIDTH-1:0] o_p3_idx             ,
        input  [LOGL-1:0]     o_p3_idy             ,
        output reg            o_p3_ready           ,
        output                o_p3_done            ,
        input  [LOGQ-1:0]     o_p3_data    [0:TP-1],
        // memory interface
        relin_t.master     relin_t
    );

localparam LOGK = LOGN -  $rtoi($ceil($clog2(TP)));
localparam K    = 1 << LOGK;
localparam LAT  = 5;



always @(posedge clk) begin
    if (rst)
        i_p0_ready <= 1;
    else if (i_p0_en)
        i_p0_ready <= 0;
    else if (i_p0_done)
        i_p0_ready <= 1;
end


always @(posedge clk) begin
    if (rst)
        i_p1_ready <= 1;
    else if (i_p1_en)
        i_p1_ready <= 0;
    else if (i_p1_done)
        i_p1_ready <= 1;
end


always @(posedge clk) begin
    if (rst)
        i_p2_ready <= 1;
    else if (i_p2_en)
        i_p2_ready <= 0;
    else if (i_p2_done)
        i_p2_ready <= 1;
end


always @(posedge clk) begin
    if (rst)
        o_p3_ready <= 1;
    else if (o_p3_en)
        o_p3_ready <= 0;
    else if (o_p3_done)
        o_p3_ready <= 1;
end



shift_reg #(
    .LAT   (LAT),
    .WIDTH (1  ),
    .RST_EN(1  )
) i_p0_valid_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (i_p0_en   ),
    .o_data (i_p0_valid)
);


shift_reg #(
    .LAT   (LAT + K),
    .WIDTH (1      ),
    .RST_EN(1      )
) i_p0_done_shift_reg (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (i_p0_en  ),
    .o_data (i_p0_done)
);


shift_reg #(
    .LAT   (LAT),
    .WIDTH (1  ),
    .RST_EN(1  )
) i_p1_valid_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (i_p1_en   ),
    .o_data (i_p1_valid)
);


shift_reg #(
    .LAT   (LAT + K),
    .WIDTH (1      ),
    .RST_EN(1      )
) i_p1_done_shift_reg (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (i_p1_en  ),
    .o_data (i_p1_done)
);


shift_reg #(
    .LAT   (LAT),
    .WIDTH (1  ),
    .RST_EN(1  )
) i_p2_valid_shift_reg (
    .clk    (clk       ),
    .rst    (rst       ),
    .i_data (i_p2_en   ),
    .o_data (i_p2_valid)
);


shift_reg #(
    .LAT   (LAT + K),
    .WIDTH (1      ),
    .RST_EN(1      )
) i_p2_done_shift_reg (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (i_p2_en  ),
    .o_data (i_p2_done)
);



shift_reg #(
    .LAT   (LAT + K),
    .WIDTH (1      ),
    .RST_EN(1      )
) o_p3_done_shift_reg (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (o_p3_en  ),
    .o_data (o_p3_done)
);


endmodule