module bram
   #(
        parameter WIDTH  = 32  ,
        parameter LENGTH = 1024
    )
    (   input                  clk,
        input                  wen,
        input      [DEPTH-1:0] waddr,
        input      [WIDTH-1:0] din,
        input      [DEPTH-1:0] raddr,
        output reg [WIDTH-1:0] dout
    );

localparam DEPTH = $rtoi($ceil($clog2(LENGTH)));

// bram
(* ram_style="block" *) reg [WIDTH-1:0] blockram [LENGTH-1:0] = '{default: {WIDTH{1'b0}}};

// write operation
always @(posedge clk) begin
    if(wen)
        blockram[waddr] <= din;
end

// read operation
always @(posedge clk) begin
    dout <= blockram[raddr];
end

endmodule