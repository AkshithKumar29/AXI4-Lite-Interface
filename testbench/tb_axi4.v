`timescale 1ns/1ps

module tb_axi4;
    // Clock and Reset
    reg clk;
    reg rst;
    
    // Master control signals
    reg start_write;
    reg start_read;
    reg [31:0] aw_add_in;
    reg [31:0] w_data_in;
    reg [31:0] ar_add_in;
    
    // Wires connecting Master and Slave
    wire aw_valid, w_valid, b_ready, ar_valid, r_ready;
    wire aw_ready, w_ready, b_valid, ar_ready, r_valid;
    wire [31:0] aw_add, w_data, ar_add, r_data;
    wire [3:0] w_strb;
    wire [1:0] b_resp, r_resp;
    wire [31:0] r_data_out;
    
    // Instantiate Master
    axi4_lite_master master (
        .clk(clk),
        .rst(rst),
        .start_write(start_write),
        .start_read(start_read),
        .aw_add_in(aw_add_in),
        .w_data_in(w_data_in),
        .ar_add_in(ar_add_in),
        .r_add_in(32'h0),  // Not used in your master
        
        // Outputs to slave
        .aw_valid(aw_valid),
        .aw_add(aw_add),
        .w_valid(w_valid),
        .w_data(w_data),
        .w_strb(w_strb),
        .b_ready(b_ready),
        .ar_valid(ar_valid),
        .ar_add(ar_add),
        .r_ready(r_ready),
        
        // Inputs from slave
        .aw_ready(aw_ready),
        .w_ready(w_ready),
        .b_valid(b_valid),
        .b_resp(b_resp),
        .ar_ready(ar_ready),
        .r_valid(r_valid),
        .r_data(r_data),
        .r_resp(r_resp),
        .r_data_out(r_data_out)
    );
    
    // Instantiate Slave
    axi4_lite_slave slave (
        .clk(clk),
        .rst(rst),
        
        // Write Address Channel
        .aw_valid(aw_valid),
        .aw_add(aw_add),
        .aw_ready(aw_ready),
        
        // Write Data Channel
        .w_valid(w_valid),
        .w_data(w_data),
        .w_strb(w_strb),
        .w_ready(w_ready),
        
        // Write Response Channel
        .b_valid(b_valid),
        .b_resp(b_resp),
        .b_ready(b_ready),
        
        // Read Address Channel
        .ar_valid(ar_valid),
        .ar_add(ar_add),
        .ar_ready(ar_ready),
        
        // Read Data Channel
        .r_valid(r_valid),
        .r_data(r_data),
        .r_resp(r_resp),
        .r_ready(r_ready)
    );
    
    // Clock Generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test Sequence
    initial begin
        // Initialize signals
        rst = 1;
        start_write = 0;
        start_read = 0;
        aw_add_in = 0;
        w_data_in = 0;
        ar_add_in = 0;
        
        // Wait for a few clocks, then release reset
        #20;
        rst = 0;
        #10;
        
        $display("========================================");
        $display("Starting AXI4-Lite Testbench");
        $display("========================================");
        
        // Test 1: Write to address 0x00
        $display("\nTest 1: Write 0xDEADBEEF to address 0x00");
        aw_add_in = 32'h00000000;
        w_data_in = 32'hDEADBEEF;
        start_write = 1;
        #10;
        start_write = 0;
        wait(master.write_done);
        #20;
        $display("Write completed!");
        
        // Test 2: Read from address 0x00
        $display("\nTest 2: Read from address 0x00");
        ar_add_in = 32'h00000000;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Read data: 0x%h (Expected: 0xDEADBEEF)", r_data_out);
        if (r_data_out == 32'hDEADBEEF)
            $display("✓ PASS: Read data matches!");
        else
            $display("✗ FAIL: Read data mismatch!");
        
        // Test 3: Write to address 0x04
        $display("\nTest 3: Write 0x12345678 to address 0x04");
        aw_add_in = 32'h00000004;
        w_data_in = 32'h12345678;
        start_write = 1;
        #10;
        start_write = 0;
        wait(master.write_done);
        #20;
        $display("Write completed!");
        
        // Test 4: Read from address 0x04
        $display("\nTest 4: Read from address 0x04");
        ar_add_in = 32'h00000004;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Read data: 0x%h (Expected: 0x12345678)", r_data_out);
        if (r_data_out == 32'h12345678)
            $display("✓ PASS: Read data matches!");
        else
            $display("✗ FAIL: Read data mismatch!");
        
        // Test 5: Verify address 0x00 still has original data
        $display("\nTest 5: Verify address 0x00 still has 0xDEADBEEF");
        ar_add_in = 32'h00000000;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Read data: 0x%h (Expected: 0xDEADBEEF)", r_data_out);
        if (r_data_out == 32'hDEADBEEF)
            $display("✓ PASS: Data preserved correctly!");
        else
            $display("✗ FAIL: Data corruption!");
        
        // Test 6: Write to all 4 registers
        $display("\nTest 6: Write to all 4 registers");
        
        aw_add_in = 32'h00000008;
        w_data_in = 32'hAAAAAAAA;
        start_write = 1;
        #10;
        start_write = 0;
        wait(master.write_done);
        #20;
        
        aw_add_in = 32'h0000000C;
        w_data_in = 32'h55555555;
        start_write = 1;
        #10;
        start_write = 0;
        wait(master.write_done);
        #20;
        
        // Read back all registers
        $display("\nTest 7: Read back all 4 registers");
        ar_add_in = 32'h00000000;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Address 0x00: 0x%h", r_data_out);
        
        ar_add_in = 32'h00000004;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Address 0x04: 0x%h", r_data_out);
        
        ar_add_in = 32'h00000008;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Address 0x08: 0x%h", r_data_out);
        
        ar_add_in = 32'h0000000C;
        start_read = 1;
        #10;
        start_read = 0;
        wait(master.read_done);
        #20;
        $display("Address 0x0C: 0x%h", r_data_out);
        
        #100;
        $display("\n========================================");
        $display("All tests completed!");
        $display("========================================");
        $finish;
    end
    
    // Optional: Dump waveforms for viewing in simulator
    initial begin
        $dumpfile("axi4_lite.vcd");
        $dumpvars(0, tb_axi4);
    end

endmodule