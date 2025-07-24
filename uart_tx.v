`timescale 1ns/1ps

module uart_tx #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1
)(
    input clk,
    input rst_n,
    input baud_tick,
    input parity_en,
    input parity_odd,
    input fifo_empty,
    input [DATA_BITS-1:0] fifo_dout,
    input fifo_rd_en_ack,  // Not used, ready for future extension
    output reg fifo_rd_en,
    output reg tx_line,
    output reg busy
);

    parameter IDLE          = 3'd0;
    parameter START_BIT     = 3'd1;
    parameter DATA_BITS_ST  = 3'd2;
    parameter PARITY_BIT_ST = 3'd3;
    parameter STOP_BITS_ST  = 3'd4;

    reg [2:0] state;
    reg [3:0] bit_index;
    reg [1:0] stop_bit_count;
    reg [DATA_BITS-1:0] tx_data;
    reg parity_bit;

    always @(*) begin
        parity_bit = parity_en ? ((parity_odd) ? ~^tx_data : ^tx_data) : 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_line <= 1'b1;
            busy <= 1'b0;
            bit_index <= 0;
            stop_bit_count <= 0;
            fifo_rd_en <= 0;
            tx_data <= 0;
        end else begin
            fifo_rd_en <= 0;

            case (state)
                IDLE: begin
                    tx_line <= 1'b1;
                    busy <= 1'b0;
                    bit_index <= 0;
                    stop_bit_count <= 0;
                    if (!fifo_empty) begin
                        fifo_rd_en <= 1;
                        busy <= 1'b1;
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    tx_line <= 1'b0;
                    if (baud_tick) begin
                        tx_data <= fifo_dout;
                        bit_index <= 0;
                        state <= DATA_BITS_ST;
                    end
                end

                DATA_BITS_ST: begin
                    tx_line <= tx_data[bit_index];
                    if (baud_tick) begin
                        if (bit_index == DATA_BITS - 1) begin
                            state <= parity_en ? PARITY_BIT_ST : STOP_BITS_ST;
                            bit_index <= 0;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end

                PARITY_BIT_ST: begin
                    tx_line <= parity_bit;
                    if (baud_tick) begin
                        state <= STOP_BITS_ST;
                        stop_bit_count <= 0;
                    end
                end

                STOP_BITS_ST: begin
                    tx_line <= 1'b1;
                    if (baud_tick) begin
                        if (stop_bit_count == STOP_BITS - 1) begin
                            state <= IDLE;
                            busy <= 0;
                        end else begin
                            stop_bit_count <= stop_bit_count + 1;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
