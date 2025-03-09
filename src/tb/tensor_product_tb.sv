`timescale 1ns/1ps
`include "modmul_wlm.svh"

module tensor_product_tb;

// Testbench parameters
parameter LOGQ  = 64;   
parameter LOGQH = 47;   
parameter TP    = 8;    
parameter LOGN  = 10;   // N must be larger than (ADD_LAT+MULT_LAT)=16

///////////////////////////// Parameters ////////////////////////////////
parameter N        = (1 << LOGN); // number of coefficients one poly have
parameter FF_ADD   = 1; 
parameter FF_IN    = 1; 
parameter FF_MUL   = 1;
parameter FF_SUM   = 0;
parameter FF_SUB   = 0;
parameter FF_OUT   = 1;
parameter USE_CSA  = 1;
parameter FF_CSA   = 1;
parameter MORE_DSP = 1;
parameter NON_STD  = 0;
parameter W = LOGQ - LOGQH;
parameter modmul_wlm_params_t params = {W, LOGQ, LOGQH, 1, FF_IN, FF_MUL, FF_SUM, FF_SUB, FF_OUT, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
parameter MULT_LAT  = modmul_wlm_lat(params);
parameter ADD_LAT   = FF_ADD + FF_IN + FF_OUT;  // Total pipeline latency
parameter LATENCY   = MULT_LAT + ADD_LAT + 2;
///////////////////////////// Parameters ////////////////////////////////

// Constants for Montgomery Multiplication
logic [LOGQH-1:0] q_int;//  = 1226;
logic [LOGQ-1:0] Q;//     = (q_int << (LOGQ - LOGQH)) + 1;
logic [LOGQ-1:0] R_INV;// = mod_inverse(1 << LOGQ, Q);

// Function to compute modular inverse using Extended Euclidean Algorithm
function automatic logic [LOGQ-1:0] mod_inverse(logic [LOGQ:0] base, logic [LOGQ-1:0] mod);
    logic [LOGQ:0] a, b, u, v, q, r, m, n;
    a = base;
    b = mod;
    u = 1;
    v = 0;
    while (a > 0) begin
        q = b / a;
        r = b % a;
        m = v - q * u;
        n = a;
        b = a;
        a = r;
        v = u;
        u = m;
    end
    if (b != 1) return 0;  // No modular inverse exists
    return (v + mod) % mod;
endfunction

// Clock and reset
logic clk;
logic rst;
logic sim_end;

// Inputs
logic load_q;
logic [LOGQH-1:0] qH;
logic i_valid;
logic [LOGQ-1:0] i_poly [TP];  

// Outputs
logic o_valid;
logic o_done;
logic o_busy;
logic [1:0] o_poly_id;
logic [LOGQ-1:0] o_poly [TP];

// Internal reference storage
logic [LOGQ-1:0] ref_x[TP][N];
logic [LOGQ-1:0] ref_y[TP][N];
logic [LOGQ-1:0] ref_z[TP][N];

// RTL output storage
logic [LOGQ-1:0] rtl_x[TP][N];
logic [LOGQ-1:0] rtl_y[TP][N];
logic [LOGQ-1:0] rtl_z[TP][N];

// Precomputed input polynomials
logic [LOGQ-1:0] poly_a[TP][N];
logic [LOGQ-1:0] poly_b[TP][N];
logic [LOGQ-1:0] poly_c[TP][N];
logic [LOGQ-1:0] poly_d[TP][N];

integer match_count;
integer loop_count;

// File for logging mismatches
integer log_file;
initial log_file = $fopen("output_log.txt", "w");
logic test_result;

// Instantiate DUT
tensor_product #(
    .LOGN(LOGN),
    .LOGQ(LOGQ),
    .LOGQH(LOGQH),
    .TP(TP)
) dut (
    .clk(clk),
    .rst(rst),
    .load_q(load_q),
    .qH(qH),
    .i_valid(i_valid),
    .i_poly(i_poly),
    .o_valid(o_valid),
    .o_done(o_done),
    .o_busy(o_busy),
    .o_poly_id(o_poly_id),
    .o_poly(o_poly)
);

// Clock generation
initial begin
    clk = 1;
    forever #5 clk = ~clk;
end

// Reset logic
initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst = 0;
end

// Task to initialize inputs
task initialize_inputs;
    begin
        sim_end = 0;
        load_q  = 0;
        qH      = 0;
        i_valid = 0;
        match_count = 0;
    end
endtask

// Task to load modulus value
task t_load_q(input logic [LOGQH-1:0] qH_in);
    begin
        Q <= (q_int << (LOGQ - LOGQH)) + 1;
        @(posedge clk); 
        R_INV <= mod_inverse(1 << LOGQ, Q);
        @(posedge clk); 
        load_q = 1;
        qH     = qH_in;
        repeat (4) @(posedge clk);
        load_q = 0;
    end
endtask

// Function to generate polynomials
task gen_poly(output logic [LOGQ-1:0] poly[TP][N], input logic [LOGQ-1:0] base_value);
    logic [LOGQ-1:0] base;
    base = base_value;
    for (integer j = 0; j < TP; j++) begin
        for (integer i = 0; i < N; i++) begin
            poly[j][i] = base + i;
        end
        base = base + 1;
    end
endtask

// Task to send polynomial data to DUT
task send_poly(input logic [LOGQ-1:0] poly[TP][N]);
    begin
        i_valid <= 1;
        @(posedge clk);
        i_valid <= 0;
        for (integer i = 0; i < N; i++) begin
            for (integer j = 0; j < TP; j++) begin
                i_poly[j] = poly[j][i];
            end
            @(posedge clk);
        end
    end
endtask

// Task to capture RTL output and compare with reference simultaneously
task capture_and_compare_output;
    integer index;
    integer poly_id;
    integer expected_poly_id;
    index = 0;
    test_result = 0;
    expected_poly_id = 0;   

    $display("[DEBUG] capture_and_compare_output started.");

    while (!sim_end) begin
        wait (o_valid);
        poly_id = o_poly_id;
        index = 0;
        @(posedge clk);
        @(posedge clk);
        $fwrite(log_file, "---- poly_id %0d ----\n", poly_id);
        
        if (expected_poly_id == poly_id) begin
            while (!o_done) begin
                $fwrite(log_file, "Index %0d: ",index);
                for (integer i = 0; i < TP; i++) begin
                    $fwrite(log_file, "%0d ", o_poly[i]);
                    case (poly_id)
                        2'b00: rtl_x[i][index] = o_poly[i];
                        2'b01: rtl_y[i][index] = o_poly[i];
                        2'b10: rtl_z[i][index] = o_poly[i];
                        default: $display("[ERROR] Unknown o_poly_id: %0d", poly_id);
                    endcase
    
                    // Compare simultaneously
                    case (poly_id)
                        2'b00: if (o_poly[i] == ref_x[i][index]) match_count++;
                        2'b01: if (o_poly[i] == ref_y[i][index]) match_count++;
                        2'b10: if (o_poly[i] == ref_z[i][index]) match_count++;
                    endcase
                end
                $fwrite(log_file, "\n");
                index++;
                @(posedge clk);
            end
        end else begin 
            $display("[ERROR] poly_id: %0d (Expected poly_id: %0d)", poly_id, expected_poly_id);
        end
                    
        if (match_count == TP*N) begin
            $display("[DEBUG] poly_id :%0d Test PASSED: No mismatches found.",poly_id);
        end else begin
            test_result = 1;
            $display("[DEBUG] poly_id :%0d Test FAILED: %0d mismatches found.",poly_id,TP*N-match_count);
        end
        match_count = 0;
        expected_poly_id = (expected_poly_id + 1) % 3;
    end
    $fclose(log_file);
    $display("[DEBUG] capture_and_compare_output finished.");
endtask

// Reference function to compute tensor product
task compute_reference_product(
    output logic [LOGQ-1:0] x[TP][N],
    output logic [LOGQ-1:0] y[TP][N],
    output logic [LOGQ-1:0] z[TP][N],
    input logic [LOGQ-1:0] a[TP][N],
    input logic [LOGQ-1:0] b[TP][N],
    input logic [LOGQ-1:0] c[TP][N],
    input logic [LOGQ-1:0] d[TP][N]
);
    logic [LOGQ-1:0] ac[TP][N];
    logic [LOGQ-1:0] bc[TP][N];
    logic [LOGQ-1:0] ad[TP][N];
    logic [LOGQ-1:0] bd[TP][N];

    for (integer i = 0; i < TP; i++) begin
        for (integer j = 0; j < N; j++) begin
            ac[i][j] = (a[i][j] * c[i][j] * R_INV) % Q;
            bc[i][j] = (b[i][j] * c[i][j] * R_INV) % Q;
            ad[i][j] = (a[i][j] * d[i][j] * R_INV) % Q;
            bd[i][j] = (b[i][j] * d[i][j] * R_INV) % Q;
            y[i][j]  = (bc[i][j] + ad[i][j]) % Q;
            x[i][j]  = ac[i][j];
            z[i][j]  = bd[i][j];
        end
    end
    
endtask


integer num_of_packets = 5;

// Stimulus procedure
initial begin

    initialize_inputs;
    @(negedge rst);

    fork capture_and_compare_output(); join_none;

    q_int <= 127;
    @(posedge clk); 
    t_load_q(q_int);
    @(posedge clk); 

    for (loop_count = 0; loop_count < num_of_packets; loop_count++) begin

        gen_poly(poly_a, 10);
        gen_poly(poly_b, 0);
        gen_poly(poly_c, 100000);
        gen_poly(poly_d, 41);
        compute_reference_product(ref_x, ref_y, ref_z, poly_a, poly_b, poly_c, poly_d);

        send_poly(poly_a);
        send_poly(poly_b);
        send_poly(poly_c);
        send_poly(poly_d);
        repeat (LATENCY) @(posedge clk); 
    end

    repeat (num_of_packets*1000) @(posedge clk);
    sim_end = 1;
        // Final comparison report
    if (test_result == 0)
        $display("[DEBUG] Test PASSED.");
    else
        $display("[DEBUG] Test FAILED.");

    $display("[DEBUG] R_INV : %d.", R_INV);

    $finish;
end

endmodule
