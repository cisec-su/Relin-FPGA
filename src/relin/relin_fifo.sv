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
        output     [LOGK-1:0]  ctr_i          ,
        input      [LOGQ-1:0]  i_data [0:TP-1],
        output     [LOGK-1:0]  ctr_o          ,
        output reg [LOGQ-1:0]  o_data [0:TP-1]
    );


localparam LOGK = $rtoi($ceil($clog2(K)));
localparam CTR_O_RST = 1;

wire [LOGK-1:0] ctr_o_int;
wire bram_wen;
wire bram_ren;

wire [LOGQ*TP-1:0] bram_in;
wire [LOGQ*TP-1:0] bram_out;

wire cache_en_idata;
wire cache_en_bram;

reg wen_q;

assign ctr_o = ctr_o_int - CTR_O_RST;

assign bram_wen = wen | (|ctr_i);
assign bram_ren = ren || (ctr_o_int != CTR_O_RST);
assign cache_en_idata = bram_wen && ((ctr_i == (ctr_o_int - CTR_O_RST)) || ((ctr_i == ctr_o_int) && (~wen_q | ren)));
assign cache_en_bram = bram_ren;


counter #(
    .WIDTH (LOGK ),
    .MAX   (K - 1) 
) ctr_i_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (wen   ),
    .ctr   (ctr_i )
);

counter #(
    .WIDTH   (LOGK     ),
    .MAX     (K - 1    ), 
    .RST_VAL (CTR_O_RST)
) ctr_o_inst (
    .clk   (clk   ),
    .rst   (rst   ),
    .inc   (ren   ),
    .ctr   (ctr_o_int )
);


bram #(
    .WIDTH (LOGQ*TP),
    .LENGTH(K   ),
    .FF_OUT(1   )
) bram_inst (
    .clk  (clk      ),
    .wen  (bram_wen ),
    .waddr(ctr_i    ),
    .din  (bram_in  ),
    .raddr(ctr_o_int),
    .dout (bram_out )
);


for (genvar i = 0; i < TP; i = i + 1) begin
    assign bram_in[i*LOGQ +: LOGQ] = i_data[i];
end




for (genvar i = 0; i < TP; i = i + 1) begin : O_DATA_GEN
    always @(posedge clk) begin
        if (cache_en_idata) begin
            o_data[i] <= i_data[i];
        end
        else if (cache_en_bram) begin
            o_data[i] <= bram_out[i*LOGQ +: LOGQ];
        end
    end
end


always @(posedge clk) begin
    wen_q <= wen;
end


endmodule