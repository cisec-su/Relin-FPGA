module relin_tb
#(   
    parameter L        = 3  , // Number of primes
    parameter LOGQ     = 64  ,
    parameter LOGQH    = 17  ,
    parameter LOGN     = 13  ,
    parameter LOGTP    = 5   ,
    parameter NUMPSI   = 1 << LOGN
)();

`include "relin_if.svh"

localparam LOGL = $rtoi($ceil($clog2(L)));


localparam HP = 2.5; // 200 MHz clock

reg clk, rst, start;
wire done;


relin_t #(
    .LOGL(LOGL),   // Adjust as needed
    .LOGQ(LOGQ),   // Adjust as needed
    .TP(1 << LOGTP)      // Adjust as needed
) relin_t_inst ();

relin #(
    .L      (L)     ,
    .LOGQ   (LOGQ)  ,
    .LOGQH  (LOGQH) ,
    .LOGN   (LOGN)  ,
    .LOGTP  (LOGTP) 
) relin_inst (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .relin_t(relin_t_inst)
);


initial begin
    clk = 0;
    forever #HP clk = ~clk;
end

initial begin
    rst = 1;
    #(4*HP) rst = 0;
end


initial begin
    start = 0;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    #1;
    start = 1;
    @(posedge clk);
    start = 0;

    while(!done) begin
        @(posedge clk);
    end
    $display("Done");
    $finish;


end




endmodule