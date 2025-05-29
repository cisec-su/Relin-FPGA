module relin_fifo
   #(   
        parameter K     = 1 ,
        parameter M     = K ,
        parameter TP    = 32,
        parameter LOGQ  = 64
    )
    (
        input              clk            ,
        input              rst            ,
        input              ren            , // reads for K cycles
        input              wen            , // writes for K cycles
        input  [LOGQ-1:0]  i_data [0:TP-1],
        output [LOGQ-1:0]  o_data [0:TP-1] // todo: fix 1 cc delay
    );


localparam LOGK = $rtoi($ceil($clog2(K)));
localparam LOGM = $rtoi($ceil($clog2(M)));

wire [LOGK-1:0] ctr_i;
wire [LOGK-1:0] ctr_o;
wire bram_wen;


assign bram_wen = wen | (|ctr_i);

counter #(
    .WIDTH(LOGK),
    .AUTO_WIDTH(LOGM)
) ctr_i_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (wen   ),
    .ctr   (ctr_i )
);

counter #(
    .WIDTH(LOGK),
    .AUTO_WIDTH(LOGM)    
) ctr_o_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (ren   ),
    .ctr   (ctr_o )
);


generate
    for (genvar i = 0; i < TP; i = i + 1) begin : BRAM_GEN
        bram #(
            .WIDTH (LOGQ),          // Data size (word size)
            .LENGTH(K   )           // Memory size
        ) bram_inst (
            .clk  (clk          ),   // Clock signal
            .wen  (bram_wen     ),   // Write enable
            .waddr(ctr_i        ),   // Write address
            .din  (i_data[i]    ),   // Data input
            .raddr(ctr_o        ),   // Read address
            .dout (o_data[i]    )    // Data output
        );
    end
endgenerate


endmodule