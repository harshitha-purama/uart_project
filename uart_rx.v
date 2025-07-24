`timescale 1ns / 1ps

module uart_rx #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1,
    parameter BAUD_PERIOD = 434  // For 50MHz/115200 baud
)(
    input clk,
    input rst_n,
    input rx_line,
    input parity_en,
    input parity_odd,

    output reg fifo_wr_en,
    output reg [DATA_BITS-1:0] fifo_din,

    output reg parity_error,
    output reg framing_error
);

    localparam IDLE          = 3'd0;
    localparam START_BIT     = 3'd1;
    localparam DATA_BITS_ST  = 3'd2;
    localparam PARITY_BIT_ST = 3'd3;
    localparam STOP_BITS_ST  = 3'd4;

    reg [2:0] state = IDLE;
    reg [9:0] baud_counter = 0;
    reg [3:0] bit_index = 0;
    reg [DATA_BITS-1:0] shift_reg = 0;
    reg [1:0] stop_bit_count = 0;
    reg parity_bit_calc;

    wire sample_point = (baud_counter == (BAUD_PERIOD >> 1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            baud_counter <= 0;
            bit_index <= 0;
            shift_reg <= 0;
            fifo_wr_en <= 0;
            stop_bit_count <= 0;
            parity_error <= 0;
            framing_error <= 0;
            fifo_din <= 0;
        end else begin
            fifo_wr_en <= 0;

            case(state)
                IDLE: begin
                    parity_error <= 0;
                    framing_error <= 0;
                    baud_counter <= 0;
                    bit_index <= 0;
                    stop_bit_count <= 0;
                    if (~rx_line) begin
                        state <= START_BIT;
                        baud_counter <= 0;
                    end
                end
                START_BIT: begin
                    baud_counter <= baud_counter + 1;
                    if (sample_point) begin
                        if (rx_line == 1'b0) begin
                            baud_counter <= 0;
                            bit_index <= 0;
                            state <= DATA_BITS_ST;
                        end else begin
                            state <= IDLE;
                        end
                    end
                    if (baud_counter == BAUD_PERIOD - 1)
                        baud_counter <= 0;
                end
                DATA_BITS_ST: begin
                    baud_counter <= baud_counter + 1;
                    if (sample_point) begin
                        shift_reg[bit_index] <= rx_line;
                        bit_index <= bit_index + 1;
                        if (bit_index == DATA_BITS - 1) begin
                            state <= parity_en ? PARITY_BIT_ST : STOP_BITS_ST;
                            baud_counter <= 0;
                        end
                    end
                    if (baud_counter == BAUD_PERIOD - 1)
                        baud_counter <= 0;
                end
                PARITY_BIT_ST: begin
                    baud_counter <= baud_counter + 1;
                    if (sample_point) begin
                        parity_bit_calc = ^shift_reg;
                        if (parity_odd)
                            parity_bit_calc = ~parity_bit_calc;
                        parity_error <= (rx_line != parity_bit_calc);
                        state <= STOP_BITS_ST;
                        stop_bit_count <= 0;
                        baud_counter <= 0;
                    end
                    if (baud_counter == BAUD_PERIOD - 1)
                        baud_counter <= 0;
                end
                STOP_BITS_ST: begin
                    baud_counter <= baud_counter + 1;
                    if (sample_point) begin
                        if (rx_line != 1'b1)
                            framing_error <= 1'b1;
                        if (stop_bit_count == STOP_BITS - 1) begin
                            fifo_wr_en <= 1'b1;
                            fifo_din <= shift_reg;
                            state <= IDLE;
                            baud_counter <= 0;
                        end else begin
                            stop_bit_count <= stop_bit_count + 1;
                        end
                    end
                    if (baud_counter == BAUD_PERIOD - 1)
                        baud_counter <= 0;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
