// debounce.v
// Synchronizes a noisy input (button/switch), debounces it, and
// gives a one-clock "rise" pulse when the clean signal goes 0 -> 1.
module debounce #(
    parameter integer STABLE_CYCLES = 2_000_000   // 20 ms at 100 MHz
)(
    input  wire clk,
    input  wire rst,
    input  wire noisy,
    output reg  clean,
    output wire rise
);
    reg s0 = 1'b0, s1 = 1'b0;
    reg [31:0] cnt = 32'd0;
    reg clean_d = 1'b0;

    initial clean = 1'b0;

    always @(posedge clk) begin
        s0 <= noisy;
        s1 <= s0;
    end

    always @(posedge clk) begin
        if (rst) begin
            cnt   <= 32'd0;
            clean <= 1'b0;
        end else if (s1 == clean) begin
            cnt <= 32'd0;
        end else if (cnt == STABLE_CYCLES - 1) begin
            clean <= s1;
            cnt   <= 32'd0;
        end else begin
            cnt <= cnt + 32'd1;
        end
    end

    always @(posedge clk) clean_d <= clean;

    assign rise = clean & ~clean_d;
endmodule
