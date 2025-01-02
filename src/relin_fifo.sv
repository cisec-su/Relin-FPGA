module relin_fifo
    #(   
        parameter K     = 1 ,
        parameter TP    = 32,
        parameter LOGQ  = 1
    )
    (
        input              clk            ,
        input              rst            ,
        input              ren            , // reads for K cycles
        input              wen            , // writes for K cycles
        input  [LOGQ-1:0]  i_data [0:TP-1],
        output [LOGQ-1:0]  o_data [0:TP-1]
    );


localparam LOGK = $rtoi($ceil($clog2(K)));


reg [LOGK-1:0] ctr_i;
reg [LOGK-1:0] ctr_o;


generate
    for (genvar i = 0; i < TP; i++) begin : RAM
        (* ram_style="block" *) reg data [0:K-1];
    end
endgenerate


always @(posedge clk) begin
    if (rst) begin
        ctr_i <= 0;
        ctr_o <= 0;
    end
    else begin
        if (wen) begin
            if (ctr_i == K-1) begin
                ctr_i <= 0;
            end
            else begin
                ctr_i <= ctr_i + 1;
            end
        end
        if (ren) begin
            if (ctr_o == K-1) begin
                ctr_o <= 0;
            end
            else begin
                ctr_o <= ctr_o + 1;
            end
        end
    end
end


generate
    for (genvar i = 0; i < TP; i++) begin
        assign o_data[i] = RAM[i].data[ctr_o];
    end
endgenerate


generate
    for (genvar i = 0; i < TP; i++) begin
        always @(posedge clk) begin
            if (wen) begin
                RAM[i].data[ctr_i] <= i_data[i];
            end
        end
    end
endgenerate


endmodule