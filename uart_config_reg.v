`timescale 1ns/1ps

module uart_config_reg(
    input clk,
    input rst_n,
    input wr_en,
    input [1:0] addr,
    input [31:0] wr_data,
    output reg [31:0] rd_data,

    output reg [31:0] baud_rate,
    output reg parity_en,
    output reg parity_odd,
    output reg [1:0] stop_bits
);

    localparam ADDR_BAUD      = 2'd0;
    localparam ADDR_PARITY    = 2'd1;
    localparam ADDR_STOP_BITS = 2'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_rate <= 115200;
            parity_en <= 0;
            parity_odd <= 0;
            stop_bits <= 1;
        end else if (wr_en) begin
            case (addr)
                ADDR_BAUD:      baud_rate <= wr_data;
                ADDR_PARITY:    begin
                                    parity_en <= wr_data[0];
                                    parity_odd <= wr_data[1];
                                end
                ADDR_STOP_BITS: stop_bits <= wr_data[1:0];
            endcase
        end
    end

    always @(*) begin
        case (addr)
            ADDR_BAUD:      rd_data = baud_rate;
            ADDR_PARITY:    rd_data = {30'd0, parity_odd, parity_en};
            ADDR_STOP_BITS: rd_data = {30'd0, stop_bits};
            default:        rd_data = 32'd0;
        endcase
    end

endmodule
