module shift_reg
    #(   
        parameter LAT    = 1,
        parameter WIDTH  = 1
    )
    (
        input               clk   ,
        input  [WIDTH-1:0]  i_data,
        output [WIDTH-1:0]  o_data
    );


reg [WIDTH-1:0] data [0:LAT-1];


always @(posedge clk) begin
    data[0] <= i_data;
end


generate
    for (genvar i = 1; i < LAT; i++) begin
        always @(posedge clk) begin
                data[i] <= data[i - 1];
        end
    end
endgenerate


assign o_data = data[LAT - 1];


endmodule