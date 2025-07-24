`timescale 1ns / 1ps

module uart_tb();

    reg clk;
    reg rst_n;

    // Configuration register interface signals
    reg cfg_wr_en;
    reg [1:0] cfg_addr;
    reg [31:0] cfg_wr_data;
    wire [31:0] cfg_rd_data;

    // UART serial lines: TX and RX loopback
    wire tx_line;
    reg rx_line;

    // FIFO interfaces
    reg tx_fifo_wr_en;
    reg [7:0] tx_fifo_din;
    wire tx_fifo_full;
    wire tx_fifo_empty;

    reg rx_fifo_rd_en;
    wire [7:0] rx_fifo_dout;
    wire rx_fifo_full;
    wire rx_fifo_empty;

    // Diagnostic signals
    wire parity_error;
    wire framing_error;
    wire uart_tx_busy;
    wire rx_data_ready;

    // Instantiate UART top module (adjust parameters if needed)
    uart_top uut (
        .clk(clk),
        .rst_n(rst_n),

        .cfg_wr_en(cfg_wr_en),
        .cfg_addr(cfg_addr),
        .cfg_wr_data(cfg_wr_data),
        .cfg_rd_data(cfg_rd_data),

        .rx_line(rx_line),
        .tx_line(tx_line),

        .tx_fifo_wr_en(tx_fifo_wr_en),
        .tx_fifo_din(tx_fifo_din),

        .rx_fifo_rd_en(rx_fifo_rd_en),
        .rx_fifo_dout(rx_fifo_dout),

        .tx_fifo_full(tx_fifo_full),
        .tx_fifo_empty(tx_fifo_empty),
        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_empty(rx_fifo_empty),

        .parity_error(parity_error),
        .framing_error(framing_error),

        .uart_tx_busy(uart_tx_busy),

        .rx_data_ready(rx_data_ready)
    );

    // Clock generation: 50 MHz (period = 20 ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Loopback RX line to TX line
    always @(tx_line) rx_line = tx_line;

    integer i;
    reg [7:0] rx_byte;

    // Write to config register task
    task write_config(input [1:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            cfg_wr_en = 1;
            cfg_addr = addr;
            cfg_wr_data = data;
            @(posedge clk);
            cfg_wr_en = 0;
            cfg_addr = 0;
            cfg_wr_data = 0;
        end
    endtask

    // Write byte to TX FIFO task
    task write_tx_fifo(input [7:0] data);
        begin
            @(posedge clk);
            // Wait if FIFO is full before writing
            while (tx_fifo_full) @(posedge clk);
            tx_fifo_din = data;
            tx_fifo_wr_en = 1;
            @(posedge clk);
            tx_fifo_wr_en = 0;
        end
    endtask

    // Read byte from RX FIFO task with timeout
    task read_rx_fifo(output [7:0] data);
        integer timeout;
        begin
            timeout = 0;
            @(posedge clk);
            // Wait for data with timeout (~1 ms max)
            while (rx_fifo_empty && (timeout < 50000)) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout == 50000) begin
                $display("Timeout waiting for RX FIFO data!");
                data = 8'h00;
            end
            else begin
                rx_fifo_rd_en = 1;
                @(posedge clk);
                data = rx_fifo_dout;
                rx_fifo_rd_en = 0;
            end
        end
    endtask

    initial begin
        // Initialize signals
        rst_n = 0;
        cfg_wr_en = 0;
        cfg_addr = 0;
        cfg_wr_data = 0;
        tx_fifo_wr_en = 0;
        tx_fifo_din = 0;
        rx_fifo_rd_en = 0;
        rx_line = 1'b1; // idle high UART line

        #100; // Wait 100 ns for reset
        rst_n = 1;

        // Configure UART: baud=115200, parity enabled + odd, stop bits = 1
        write_config(2'd0, 115200);  // Baud rate
        write_config(2'd1, 2);       // Parity enable=1, odd=1 (bit1=odd, bit0=enable)
        write_config(2'd2, 1);       // Stop bits = 1

        #1000;

        // Send 8 bytes with sufficient delay for UART transfer to complete each byte
        for (i = 0; i < 8; i = i + 1) begin
            $display("Sending byte %0d: 0x%0h", i, 8'hA0 + i);
            write_tx_fifo(8'hA0 + i);
            // Delay > 87 us (UART byte time at 115200 baud)
            #100000; // 100 us delay
        end

        // Read back the 8 bytes from RX FIFO
        for (i = 0; i < 8; i = i + 1) begin
            read_rx_fifo(rx_byte);
            $display("Received byte %0d: 0x%0h", i, rx_byte);
        end

        #50000;

        $display("Parity Error Flag: %b", parity_error);
        $display("Framing Error Flag: %b", framing_error);

        $display("UART loopback test finished.");
        $finish;
    end

    // Dump waveform to view in GTKWave
    initial begin
        $dumpfile("uart_wave.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule

