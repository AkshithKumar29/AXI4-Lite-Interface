module axi4_lite_slave(
    input clk, rst, aw_valid, w_valid, b_ready, ar_valid, r_ready,
    input [31:0] aw_add, w_data, ar_add,
    input [3:0] w_strb, 
    output reg aw_ready, w_ready, b_valid, ar_ready, r_valid, 
    output reg [1:0] b_resp, r_resp,
    output reg [31:0] r_data
);
    localparam wr_idle      = 2'b00;
    localparam wr_wait_data = 2'b01;
    localparam wr_send_resp = 2'b10;
    localparam rd_idle      = 1'b0;
    localparam rd_data      = 1'b1;
    
    reg [1:0] wr_state;
    reg rd_state;
    reg [31:0] mem[0:3];
    reg [31:0] aw_address, ar_address;
    integer i; 
    
    // Write State Machine
    always @(posedge clk) begin
        if (rst) begin
            aw_ready   <= 1'b1; 
            w_ready    <= 1'b0; 
            b_valid    <= 1'b0; 
            b_resp     <= 2'b0; 
            wr_state   <= 2'b0;
            for (i = 0; i <= 3; i = i + 1) begin
                mem[i] <= 32'b0;
            end
            aw_address <= 32'b0;
        end
        else begin
            case (wr_state) 
                wr_idle: begin
                    if (aw_valid && aw_ready) begin
                        aw_address <= aw_add;
                        aw_ready <= 1'b0;
                        wr_state <= wr_wait_data; 
                    end
                end
                wr_wait_data: begin
                    w_ready <= 1'b1;
                    if (w_valid && w_ready) begin
                       mem[aw_address[3:2]] <= w_data;
                       w_ready <= 1'b0;
                       wr_state <= wr_send_resp;
                    end
                end
                wr_send_resp: begin
                    b_valid <= 1'b1;
                    b_resp <= 2'b00;
                    if (b_valid && b_ready) begin
                        b_valid <= 1'b0;
                        wr_state <= wr_idle; 
                        aw_ready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // Read State Machine
    always @(posedge clk) begin
        if(rst) begin
            ar_ready   <= 1'b1;
            r_valid    <= 1'b0; 
            r_data     <= 32'b0; 
            r_resp     <= 2'b0;
            rd_state   <= 1'b0;
            ar_address <= 32'b0;  
        end
        else begin
            case (rd_state)
                rd_idle: begin
                    if(ar_valid && ar_ready) begin
                        ar_address <= ar_add;
                        ar_ready <= 1'b0;
                        rd_state <= rd_data;
                    end
                end
                rd_data: begin
                    r_data    <= mem[ar_address[3:2]];
                    r_valid   <= 1'b1;
                    r_resp    <= 2'b00;
                    if(r_valid && r_ready) begin
                        r_valid  <= 1'b0;
                        rd_state <= rd_idle;
                        ar_ready <= 1'b1; 
                    end
                end
            endcase
        end
    end
endmodule