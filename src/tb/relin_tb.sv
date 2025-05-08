module relin_tb
#(   
    parameter L        = 10  , // Number of primes
    parameter LOGQ     = 60  ,
    parameter LOGQH    = 17  ,
    parameter LOGN     = 12  , //16
    parameter LOGTP    = 5   ,
    parameter NUMPSI   = 1 << LOGN
)();

`include "relin_if.svh"

localparam LOGL = $rtoi($ceil($clog2(L)));

localparam TP = 1 << LOGTP;
localparam HP = 2.5; // 200 MHz clock
localparam N_x = 1 << 3;

reg clk, rst, start;
wire done;

relin_t #(
  .LOGL(LOGL),    // From tb parameters
  .LOGQ(LOGQ),    // From tb parameters
  .TP(TP)// TP = 2^LOGTP
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

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
end

// Reset logic
initial begin
    rst = 1;
    start = 0;
    #20;
    rst = 0;
    #20;
    start = 1;
    #10;
    start = 0;
end
parameter ID_WIDTH = 4;
// Random driver for i_p0

localparam LOGK = LOGN -  $rtoi($ceil($clog2(TP)));
localparam K    = 128;//1 << LOGK;
localparam LAT  = 5;

`define POLY_2 4'd2
`define PSI    4'd3
localparam MAX_LINES = 160000;

integer file;
integer status;
string line;
logic [LOGQ-1:0] ntt_data [0:MAX_LINES-1];
logic [LOGQ-1:0] psi_data [0:MAX_LINES-1];
logic [LOGQ-1:0] data_array [0:MAX_LINES-1];

int ntt_len; 
int psi_len;
int data_len;
int offset;
int num_cycles;
int opmode;
int ntt_input_TP;

initial begin : respond_to_i_p0_en
    relin_t_inst.i_p0_valid = 0;
    relin_t_inst.i_p0_done  = 0;
    relin_t_inst.i_p0_ready = 1;

    // Preload both files into memory

    ntt_len = 0; 
    psi_len = 0; 
    data_len = 0;


    // --- Load ntt_in.txt ---
    file = $fopen("/home/ahmetmalal/Desktop/repo/Relin-FPGA/src/tb/ntt_in.txt", "r");
    if (!file) $fatal("Failed to open ntt_in.txt");
    while (!$feof(file)) begin
        status = $fgets(line, file);
        if (status > 0) begin
            status = $sscanf(line, "%h", ntt_data[ntt_len]);
            if (status == 1) ntt_len++;
        end
    end
    $fclose(file);

    // --- Load psi.txt ---
    file = $fopen("/home/ahmetmalal/Desktop/repo/Relin-FPGA/src/tb/psi.txt", "r");
    if (!file) $fatal("Failed to open psi.txt");
    while (!$feof(file)) begin
        status = $fgets(line, file);
        if (status > 0) begin
            status = $sscanf(line, "%h", psi_data[psi_len]);
            if (status == 1) psi_len++;
        end
    end
    $fclose(file);

    // --- Main Response Loop ---
    forever begin
        @(posedge clk);

        if (relin_t_inst.i_p0_en && relin_t_inst.i_p0_ready) begin
            relin_t_inst.i_p0_ready <= 0;

            opmode = relin_t_inst.i_p0_idx;
            offset = 0;

            if (relin_t_inst.i_p0_idx == `PSI) begin
                data_len = psi_len;
                ntt_input_TP = TP / (N_x) * (N_x-1);
                num_cycles = psi_len / ntt_input_TP + ((psi_len % ntt_input_TP) ? 1 : 0);
                for (int i = 0; i < psi_len; i++) 
                    data_array[i] = psi_data[i];
            end
            else if (relin_t_inst.i_p0_idx == `POLY_2) begin
                data_len = ntt_len;
                num_cycles = ntt_len / TP + ((ntt_len % TP) ? 1 : 0);
                //num_cycles = LAT + K;
                for (int i = 0; i < ntt_len; i++) 
                    data_array[i] = ntt_data[i];
            end
            else begin
                ntt_input_TP = TP;
                num_cycles = LAT + K;
            end

            //num_cycles = LAT + K;
            
            repeat (LAT) @(posedge clk);
            // Pulse valid
            relin_t_inst.i_p0_valid <= 1;
            @(posedge clk);
            relin_t_inst.i_p0_valid <= 0;

            // Feed data
            for (int cycle = 0; cycle < num_cycles; cycle++) begin
                for (int j = 0; j < ntt_input_TP; j++) begin
                    if (offset < data_len) begin
                        relin_t_inst.i_p0_data[j] <= data_array[offset++];
                    end else begin
                        relin_t_inst.i_p0_data[j] <= 64'h0;
                    end
                end
                @(posedge clk);
            end

            // Pulse done
            relin_t_inst.i_p0_done <= 1;
            @(posedge clk);
            relin_t_inst.i_p0_done <= 0;

            // Re-enable ready
            relin_t_inst.i_p0_ready <= 1;
        end
    end
end


initial begin : respond_to_i_p1_en
    relin_t_inst.i_p1_valid = 0;
    relin_t_inst.i_p1_done  = 0;
    relin_t_inst.i_p1_ready = 1;

    for (int j = 0; j < TP; j++) begin
        relin_t_inst.i_p1_data[j] = '0;
    end

    forever begin
        @(posedge clk);

        if (relin_t_inst.i_p1_en && relin_t_inst.i_p1_ready) begin
            relin_t_inst.i_p1_ready <= 0;

            relin_t_inst.i_p1_valid <= 1;
            @(posedge clk);
            relin_t_inst.i_p1_valid <= 0;

            for (int cycle = 0; cycle < K + LAT; cycle++) begin
                for (int j = 0; j < TP; j++) begin
                    relin_t_inst.i_p1_data[j] <= 32'd20000 + j + cycle * TP;
                end
                @(posedge clk);
            end

            relin_t_inst.i_p1_done <= 1;
            @(posedge clk);
            relin_t_inst.i_p1_done <= 0;

            relin_t_inst.i_p1_ready <= 1;
        end
    end
end


// Random driver for i_p2
initial begin : respond_to_i_p2_en
    relin_t_inst.i_p2_valid = 0;
    relin_t_inst.i_p2_done  = 0;
    relin_t_inst.i_p2_ready = 1;

    for (int j = 0; j < TP; j++) begin
        relin_t_inst.i_p2_data[j] = '0;
    end

    forever begin
        @(posedge clk);

        if (relin_t_inst.i_p2_en && relin_t_inst.i_p2_ready) begin
            relin_t_inst.i_p2_ready <= 0;

            relin_t_inst.i_p2_valid <= 1;
            @(posedge clk);
            relin_t_inst.i_p2_valid <= 0;

            for (int cycle = 0; cycle < K + LAT; cycle++) begin
                for (int j = 0; j < TP; j++) begin
                    relin_t_inst.i_p2_data[j] <= 32'd30000 + j + cycle * TP;
                end
                @(posedge clk);
            end

            relin_t_inst.i_p2_done <= 1;
            @(posedge clk);
            relin_t_inst.i_p2_done <= 0;

            relin_t_inst.i_p2_ready <= 1;
        end
    end
end

initial begin : accept_o_p3_write
    relin_t_inst.o_p3_done  = 0;
    relin_t_inst.o_p3_ready = 1;

    forever begin
        @(posedge clk);

        if (relin_t_inst.o_p3_en && relin_t_inst.o_p3_ready) begin
            $display("[TB] o_p3_en received at %0t (idx=%0d, idy=%0d)", 
                      $time, relin_t_inst.o_p3_idx, relin_t_inst.o_p3_idy);

            // Optionally: log or verify o_p3_data here
            for (int cycle = 0; cycle < K + LAT; cycle++) begin
                for (int j = 0; j < TP; j++) begin
                    $display("[TB][o_p3] data[%0d] = %h", j, relin_t_inst.o_p3_data[j]);
                end
                @(posedge clk);
            end

            // Simulate data accepted: pulse done
            relin_t_inst.o_p3_done <= 1;
            @(posedge clk);
            relin_t_inst.o_p3_done <= 0;
        end
    end
end



// Monitor Done
initial begin
    wait (done == 1);
    $display("[relin_tb] DONE signal asserted at time %0t", $time);
    #50;//
    $finish;
end


endmodule