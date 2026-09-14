module regfile_tb;

    // Testbench signals
    logic clk;
    logic reset;

    logic [4:0] r_addr1;
    logic [4:0] r_addr2;

    logic we;
    logic [4:0] w_addr;
    logic [31:0] w_data;

    logic [31:0] r_data1;
    logic [31:0] r_data2;

    // Instantiate the regfile module
    regfile dut (
        .clk(clk),
        .reset(reset),
        .r_addr1(r_addr1),
        .r_addr2(r_addr2),
        .we(we),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_data1(r_data1),
        .r_data2(r_data2)
    );

    initial begin
        $dumpfile("regfile_simulation.vcd"); // Name of the output file
        $dumpvars(0, regfile_tb);                // Dump all signals in tb_top and below
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    // Test sequence
    initial begin
        $display("Starting regfile testbench...");

        // Initialize reset
        reset = 1;
        #10;
        reset = 0; // Release reset

        // Write some values to registers
        we = 1;
        w_addr = 5'd1; w_data = 32'hA5A5A5A5; #10; // Write to R1
        w_addr = 5'd2; w_data = 32'h5A5A5A5A; #10; // Write to R2
        w_addr = 5'd3; w_data = 32'hFFFFFFFF; #10; // Write to R3

        we = 0; // Disable write

        // Read back the values
        r_addr1 = 5'd1; r_addr2 = 5'd2; #10;
        $display("Read R1: %h, Read R2: %h", r_data1, r_data2);

        r_addr1 = 5'd3; r_addr2 = 5'd0; #10;
        $display("Read R3: %h, Read R0: %h", r_data1, r_data2);


        // Test write and read same cycle
        w_addr = 5'd1; w_data = 32'h12345678; we = 1; 
        r_addr1 = 5'd1; r_addr2 = 5'd1; 
        #10;
        $display("Read R1 (should be %h): %h, Read R2: %h", w_data, r_data1, r_data2);
        we = 0;  

        // Finish simulation
        $finish;
    end

endmodule