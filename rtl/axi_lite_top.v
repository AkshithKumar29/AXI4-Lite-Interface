module axi4_lite_top(
    input clk,
    input rst,
    input start_write,
    input start_read,
    input [31:0] aw_add_in,
    input [31:0] w_data_in,
    input [31:0] ar_add_in,
    output [31:0] r_data_out,
    output write_done,
    output read_done
);
    // Internal wires connecting Master and Slave
    wire aw_valid, w_valid, b_ready, ar_valid, r_ready;
    wire aw_ready, w_ready, b_valid, ar_ready, r_valid;
    wire [31:0] aw_add, w_data, ar_add, r_data;
    wire [3:0] w_strb;
    wire [1:0] b_resp, r_resp;
    
    // Instantiate Master
    axi4_lite_master master (
        .clk(clk),
        .rst(rst),
        .start_write(start_write),
        .start_read(start_read),
        .aw_add_in(aw_add_in),
        .w_data_in(w_data_in),
        .ar_add_in(ar_add_in),
        .r_add_in(32'h0),
        
        .aw_valid(aw_valid),
        .aw_add(aw_add),
        .w_valid(w_valid),
        .w_data(w_data),
        .w_strb(w_strb),
        .b_ready(b_ready),
        .ar_valid(ar_valid),
        .ar_add(ar_add),
        .r_ready(r_ready),
        
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
        
        .aw_valid(aw_valid),
        .aw_add(aw_add),
        .aw_ready(aw_ready),
        
        .w_valid(w_valid),
        .w_data(w_data),
        .w_strb(w_strb),
        .w_ready(w_ready),
        
        .b_valid(b_valid),
        .b_resp(b_resp),
        .b_ready(b_ready),
        
        .ar_valid(ar_valid),
        .ar_add(ar_add),
        .ar_ready(ar_ready),
        
        .r_valid(r_valid),
        .r_data(r_data),
        .r_resp(r_resp),
        .r_ready(r_ready)
    );
    
    // Connect write_done and read_done from master
    assign write_done = master.write_done;
    assign read_done = master.read_done;

endmodule