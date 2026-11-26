// seg7_mux.v
// Shows a 0..99 value on one 4-digit common-anode display
// (digit 0 = ones, digit 1 = tens with leading-zero blanking, others blank).
// an[] and seg[] are ACTIVE LOW. seg[0]=a ... seg[6]=g, seg[7]=dp.
// If digits appear mirrored on the board, set REVERSE = 1.
module seg7_mux #(
    parameter REVERSE = 0
)(
    input  wire       clk,
    input  wire [6:0] value,
    output reg  [3:0] an,
    output reg  [7:0] seg
);
    reg [16:0] cnt = 17'd0;
    always @(posedge clk) cnt <= cnt + 17'd1;

    wire [1:0] sel = cnt[16:15];
    wire [1:0] idx = REVERSE ? ~sel : sel;

    wire [3:0] tens = value / 7'd10;
    wire [3:0] ones = value % 7'd10;

    function [7:0] dec;
        input [3:0] d;
        case (d)
            4'd0: dec = 8'hC0;
            4'd1: dec = 8'hF9;
            4'd2: dec = 8'hA4;
            4'd3: dec = 8'hB0;
            4'd4: dec = 8'h99;
            4'd5: dec = 8'h92;
            4'd6: dec = 8'h82;
            4'd7: dec = 8'hF8;
            4'd8: dec = 8'h80;
            4'd9: dec = 8'h90;
            default: dec = 8'hFF;
        endcase
    endfunction

    always @* begin
        an      = 4'b1111;
        an[sel] = 1'b0;
        case (idx)
            2'd0:    seg = dec(ones);
            2'd1:    seg = (tens == 4'd0) ? 8'hFF : dec(tens);
            default: seg = 8'hFF;
        endcase
    end
endmodule
