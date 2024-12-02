//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: hadamart_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for the hadamart module
// 
// Dependencies: hadamart.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module hadamart_tb;

localparam W = 64;   
localparam TP = 32;  
localparam HP = 5;   
localparam FP = 2 * HP; 

reg clk;
reg rst;

reg [W-1:0] q;
reg [W-1:0] A [TP-1:0];
reg [W-1:0] B [TP-1:0];

wire [W-1:0] C [TP-1:0];

hadamart #(
    .W(W),
    .TP(TP)
) dut (
    .clk(clk),
    .rst(rst),
    .q(q),
    .A(A),
    .B(B),
    .C(C)
);

always #HP clk = ~clk;

integer idx;
integer file_A, file_B, file_q, file_python;
integer status_A, status_B, status_q, status_python;
integer rewind_status_A, rewind_status_B;

reg [W-1:0] C_python [0:TP-1];

integer num_lines_A = 0;
integer num_lines_B = 0;
integer min_num_lines;
integer current_set = 0;
integer result_mismatch = 0;
integer num_sets = 0;
integer num_elements_C = 0;
integer done_set = 0;
integer latency = 10;

function integer count_lines;
    input integer file;
    integer char;
    integer lines;
    begin
        lines = 0;
        while (!$feof(file)) begin
            char = $fgetc(file);
            if (char == "\n") begin
                lines = lines + 1;
            end
        end
        count_lines = lines;
        $display("Lines %0d", count_lines);
    end
endfunction


initial begin
    $display("Starting simulation.");
    
    clk = 1'b0;
    rst = 1'b0;
    #FP;
    rst = 1'b1;
    #FP;
    rst = 1'b0;
    #HP;
    
    file_A = $fopen("../../../../../test_vectors/A.txt", "r");
    file_B = $fopen("/home/berenaydogan/Desktop/Project/Simulation/B.txt", "r");
    file_q = $fopen("/home/berenaydogan/Desktop/Project/Simulation/q.txt", "r");
    file_python = $fopen("/home/berenaydogan/Desktop/Project/Simulation/python_results.txt", "r");
    
    if (file_A == 0 || file_B == 0 || file_q == 0 || file_python == 0) begin
        $display("Error: One of the files could not be opened.");
        $finish;
    end

    num_lines_A = count_lines(file_A);
    num_lines_B = count_lines(file_B);

    min_num_lines = (num_lines_A < num_lines_B) ? num_lines_A : num_lines_B;
    $display("min_num_lines%0d", min_num_lines);

    num_sets = min_num_lines / TP;
    num_elements_C = num_sets * TP;
    
    num_lines_A = count_lines(file_A);
    
    rewind_status_A = $fseek(file_A, 0, 0);
    if (rewind_status_A != 0) begin
        $display("Error: Could not rewind file_A.");
    end
    
    rewind_status_B = $fseek(file_B, 0, 0);
    if (rewind_status_B != 0) begin
        $display("Error: Could not rewind file_B.");
    end

    
    for (current_set = 0; current_set < num_sets; current_set = current_set + 1) begin
        $display("Processing input set %0d", current_set);
        
        for (idx = 0; idx < TP; idx = idx + 1) begin
            status_A = $fscanf(file_A, "%h\n", A[idx]);
            status_B = $fscanf(file_B, "%h\n", B[idx]);
            
            if (idx == 0 && current_set == 0) begin
                status_q = $fscanf(file_q, "%h\n", q);
            end
         
            if (status_A != 1 || status_B != 1 || status_q != 1) begin
                $display("Error while reading inputs for set %0d at index %0d", current_set, idx);
                $finish;
            end
        end
        
        #FP;
        
        if (current_set >= (latency - 1)) begin
            for (idx = 0; idx < TP; idx = idx + 1) begin
                status_python = $fscanf(file_python, "%h\n", C_python[idx]); 
                if (status_python != 1) begin
                    $display("Error while reading from file python_results.txt at index %0d", idx);
                    $finish;
                end
            end
            
            for (idx = 0; idx < TP; idx = idx + 1) begin
                if (C[idx] == C_python[idx]) begin
                    $display("Test Passed -> Set[%0d] C[%0d] = %x", done_set, idx, C[idx]);
                end else begin
                    result_mismatch = result_mismatch + 1;
                    $display("Test Failed -> Set[%0d] C[%0d] = %x, Expected C[%0d] = %x", 
                              done_set, idx, C[idx], idx, C_python[idx]);
                end
            end
            
            done_set = done_set + 1;
        end
    end
    
    
    
    if (num_sets <= latency) begin
        for (current_set = 0; current_set < num_sets; current_set = current_set + 1) begin
            for (idx = 0; idx < TP; idx = idx + 1) begin
                status_python = $fscanf(file_python, "%h\n", C_python[idx]); 
                if (status_python != 1) begin
                    $display("Error while reading from file python_results.txt at index %0d", idx);
                    $finish;
                end
            end
            
            if (num_sets < latency) begin
                if (current_set == 0) begin
                    #(FP * (10 - num_sets));
                end
                
                if (current_set != 0) begin
                    #FP;  
                end
            end
            
            
            for (idx = 0; idx < TP; idx = idx + 1) begin
                if (C[idx] == C_python[idx]) begin
                    $display("Test Passed -> Set[%0d] C[%0d] = %x", current_set, idx, C[idx]);
                end else begin
                    result_mismatch = result_mismatch + 1;
                    $display("Test Failed -> Set[%0d] C[%0d] = %x, Expected C[%0d] = %x", 
                              current_set, idx, C[idx], idx, C_python[idx]);
                end
            end
            
            if (num_sets == latency) begin
                #FP;
            end
        end
        
        if (result_mismatch == 0) begin
            $display("All test sets passed.");
        end else begin
            $display("There were %0d mismatches in the results.", result_mismatch);
        end
    
        $fclose(file_A);
        $fclose(file_B);
        $fclose(file_q);
        $fclose(file_python);
    
        $finish;
    end


    if (num_sets > latency) begin
        for (current_set = done_set; current_set < num_sets ; current_set = current_set + 1) begin
            for (idx = 0; idx < TP; idx = idx + 1) begin
                status_python = $fscanf(file_python, "%h\n", C_python[idx]); 
                if (status_python != 1) begin
                    $display("Error while reading from file python_results.txt at index %0d", idx);
                    $finish;
                end
            end
            
            #FP
      
            
            for (idx = 0; idx < TP; idx = idx + 1) begin
                if (C[idx] == C_python[idx]) begin
                    $display("Test Passed -> Set[%0d] C[%0d] = %x", current_set, idx, C[idx]);
                end else begin
                    result_mismatch = result_mismatch + 1;
                    $display("Test Failed -> Set[%0d] C[%0d] = %x, Expected C[%0d] = %x", 
                              current_set, idx, C[idx], idx, C_python[idx]);
                end
            end

        end
        
        if (result_mismatch == 0) begin
            $display("All test sets passed.");
        end else begin
            $display("There were %0d mismatches in the results.", result_mismatch);
        end
    
        $fclose(file_A);
        $fclose(file_B);
        $fclose(file_q);
        $fclose(file_python);
    
        $finish;
    end
    
end

endmodule
