module counter
   #(
        parameter WIDTH      = 10,
        parameter AUTO_INC   = 1 ,
        parameter AUTO_WIDTH = WIDTH,
        parameter MAX        = 0
    )
    (   input                  clk  ,
        input                  rst  ,
        input                  inc  ,
        output reg [WIDTH-1:0] ctr
    );



always @(posedge clk) begin
    if (rst) begin
        ctr <= 0;
    end
    else if (MAX && (ctr == MAX) && (AUTO_INC || inc)) begin
        ctr <= 0;
    end
    else if (inc || (AUTO_INC && (ctr[AUTO_WIDTH-1:0] != {AUTO_WIDTH{1'b0}}))) begin
        ctr <= ctr + 1;
    end
end


endmodule