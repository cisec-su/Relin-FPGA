module relin_fifo
   #(   
        parameter K     = 1 ,
        parameter TP    = 32,
        parameter LOGQ  = 64
    )
    (
        input                  clk            ,
        input                  rst            ,
        input                  ren            ,
        input                  wen            ,
        input      [LOGQ-1:0]  i_data [0:TP-1],
        output reg [LOGQ-1:0]  o_data [0:TP-1]
    );


localparam LOGK = $rtoi($ceil($clog2(K)));
localparam CTR_O_RST = 1;

wire [LOGK-1:0] ctr_i;
wire [LOGK-1:0] ctr_o;
wire bram_wen;
wire bram_ren;

wire [LOGQ-1:0] bram_out [0:TP-1];

wire cache_en_idata;
wire cache_en_bram;


assign bram_wen = wen | (|ctr_i);
assign bram_ren = ren || (ctr_o != CTR_O_RST);
assign cache_en_idata = (bram_wen && (ctr_i == (ctr_o - CTR_O_RST)));
assign cache_en_bram = bram_ren;


counter #(
    .WIDTH (LOGK)
) ctr_i_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (wen   ),
    .ctr   (ctr_i )
);

counter #(
    .WIDTH   (LOGK     ),
    .RST_VAL (CTR_O_RST)
) ctr_o_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (ren   ),
    .ctr   (ctr_o )
);


for (genvar i = 0; i < TP; i = i + 1) begin : BRAM_GEN
    bram #(
        .WIDTH (LOGQ),
        .LENGTH(K   ),
        .FF_OUT(0   )
    ) bram_inst (
        .clk  (clk          ),
        .wen  (bram_wen     ),
        .waddr(ctr_i        ),
        .din  (i_data[i]    ),
        .raddr(ctr_o        ),
        .dout (bram_out[i]  )
    );
end


for (genvar i = 0; i < TP; i = i + 1) begin : O_DATA_GEN
    always @(posedge clk) begin
        if (bram_ren) begin
            o_data[i] <= bram_out[i];
        end
        else if (cache_en_idata) begin
            o_data[i] <= i_data[i];
        end
    end
end


endmodule