`timescale 1ns / 1ps

module uart_top #(
    parameter DATA_BITS = 8,
    parameter FIFO_DEPTH = 16
)(
    input clk,
    input rst_n,

    // Configuration register interface
    input cfg_wr_en,
    input [1:0] cfg_addr,
    input [31:0] cfg_wr_data,
    output [31:0] cfg_rd_data,

    // UART serial lines
    input rx_line,
    output tx_line,

    // User interface to write data into TX FIFO
    input tx_fifo_wr_en,
    input [DATA_BITS-1:0] tx_fifo_din,

    // User interface to read data from RX FIFO
    input rx_fifo_rd_en,
    output [DATA_BITS-1:0] rx_fifo_dout,

    // FIFO status outputs
    output tx_fifo_full,
    output tx_fifo_empty,
    output rx_fifo_full,
    output rx_fifo_empty,

    // Diagnostic error signals
    output parity_error,
    output framing_error,

    // UART transmitter busy indicator
    output uart_tx_busy,

    // For testbench convenience: output current RX data valid flag
    output rx_data_ready
);

    // Config signals
    wire [31:0] baud_rate;
    wire parity_en;
    wire parity_odd;
    wire [1:0] stop_bits;

    // Baud tick
    wire baud_tick;

    // FIFO signals
    wire tx_fifo_empty_wire, tx_fifo_full_wire, tx_fifo_rd_en_wire;
    wire [DATA_BITS-1:0] tx_fifo_dout_wire;
    wire rx_fifo_full_wire, rx_fifo_empty_wire, rx_fifo_wr_en_wire;
    wire [DATA_BITS-1:0] rx_fifo_din_wire;

    // Instantiate configuration registers
    uart_config_reg config_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(cfg_wr_en),
        .addr(cfg_addr),
        .wr_data(cfg_wr_data),
        .rd_data(cfg_rd_data),
        .baud_rate(baud_rate),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .stop_bits(stop_bits)
    );

    // Instantiate baud rate generator (50MHz system clock assumed)
    baud_rate_gen #(
        .CLK_FREQ(50000000)
    ) baud_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // TX FIFO instance
    fifo #(
        .DATA_WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(4)
    ) tx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tx_fifo_wr_en),
        .rd_en(tx_fifo_rd_en_wire),
        .din(tx_fifo_din),
        .dout(tx_fifo_dout_wire),
        .full(tx_fifo_full_wire),
        .empty(tx_fifo_empty_wire)
    );

    // RX FIFO instance
    fifo #(
        .DATA_WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(4)
    ) rx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(rx_fifo_wr_en_wire),
        .rd_en(rx_fifo_rd_en),
        .din(rx_fifo_din_wire),
        .dout(rx_fifo_dout),
        .full(rx_fifo_full_wire),
        .empty(rx_fifo_empty_wire)
    );

    // UART transmitter
    uart_tx #(
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(1)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .parity_en(parity_en),
        .parity_odd(parity_odd),

        .fifo_empty(tx_fifo_empty_wire),
        .fifo_dout(tx_fifo_dout_wire),
        .fifo_rd_en_ack(tx_fifo_rd_en_wire),
        .fifo_rd_en(tx_fifo_rd_en_wire),

        .tx_line(tx_line),
        .busy(uart_tx_busy)
    );
    uart_rx #(
    .DATA_BITS(DATA_BITS),
    .STOP_BITS(1),
    .BAUD_PERIOD(434)
    ) uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_line(rx_line),
    .parity_en(parity_en),
    .parity_odd(parity_odd),
    .fifo_wr_en(rx_fifo_wr_en_wire),
    .fifo_din(rx_fifo_din_wire),
    .parity_error(parity_error),
    .framing_error(framing_error)
    );


    // Connect outputs
    assign tx_fifo_full = tx_fifo_full_wire;
    assign tx_fifo_empty = tx_fifo_empty_wire;
    assign rx_fifo_full = rx_fifo_full_wire;
    assign rx_fifo_empty = rx_fifo_empty_wire;

    assign rx_data_ready = ~rx_fifo_empty_wire;

endmodule

