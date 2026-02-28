module axi4_lite_master(
    input clk, rst, aw_ready, w_ready, b_valid, ar_ready, r_valid, start_write, start_read, 
    input [1:0] b_resp, r_resp, 
    input [31:0] r_data, aw_add_in, w_data_in, ar_add_in, r_add_in, 
    output reg aw_valid, w_valid, b_ready, ar_valid, r_ready,
    output reg [3:0] w_strb,
    output reg [31:0] aw_add, w_data, ar_add, r_data_out 
);
    parameter idle     = 3'b000;
    parameter aw_phase = 3'b001;
    parameter w_phase  = 3'b010;
    parameter b_phase  = 3'b011;
    parameter ar_phase = 3'b100;
    parameter r_phase  = 3'b101;
    
    reg [2:0] state;
    reg write_done, write_error, read_done, read_error; 
    reg [1:0] last_error;
    
    always @(posedge clk) begin
        if (rst) begin
            state       <= idle; 
            aw_valid    <= 1'b0;
            w_valid     <= 1'b0;
            b_ready     <= 1'b0;
            ar_valid    <= 1'b0;
            r_ready     <= 1'b0;
            w_strb      <= 4'b0;
            aw_add      <= 32'b0;
            w_data      <= 32'b0;
            ar_add      <= 32'b0;
            write_done  <= 1'b0;
            write_error <= 1'b0;
            read_done   <= 1'b0;
            read_error  <= 1'b0;
            last_error  <= 2'b00;
        end
        else begin
            case (state)
                idle: begin
                    if (start_write) begin
                        state <= aw_phase; 
                    end
                    else if (start_read) begin 
                        state <= ar_phase; 
                    end
                end
                
                aw_phase: begin
                    aw_valid <= 1'b1; 
                    aw_add   <= aw_add_in;
                    if (aw_ready) begin
                        aw_valid <= 1'b0;
                        state <= w_phase;
                    end
                end
                
                w_phase: begin
                    w_valid <= 1'b1; 
                    w_data  <= w_data_in; 
                    w_strb  <= 4'b1111;
                    if (w_ready) begin
                        w_valid <= 1'b0;
                        state <= b_phase; 
                    end
                end
                
                b_phase: begin
                    b_ready <= 1'b1;
                    if (b_valid) begin
                        b_ready <= 1'b0;  
                        if (b_resp == 2'b00) begin
                            write_done  <= 1'b1;
                            write_error <= 1'b0; 
                        end
                        else begin
                            write_done  <= 1'b0; 
                            write_error <= 1'b1; 
                            last_error  <= b_resp; 
                        end
                        state <= idle; 
                    end
                end
                
                ar_phase: begin
                    ar_valid <= 1'b1;
                    ar_add   <= ar_add_in; 
                    if (ar_ready) begin
                        ar_valid <= 1'b0;
                        state <= r_phase; 
                    end
                end
                
                r_phase: begin
                    r_ready <= 1'b1;
                    if (r_valid) begin
                        r_ready <= 1'b0;  
                        if (r_resp == 2'b00) begin
                            read_done  <= 1'b1;
                            read_error <= 1'b0;
                            r_data_out <= r_data; 
                        end
                        else begin
                            read_done  <= 1'b0;
                            read_error <= 1'b1;
                            last_error <= r_resp; 
                        end
                        state <= idle; 
                    end
                end
            endcase
        end
    end
endmodule