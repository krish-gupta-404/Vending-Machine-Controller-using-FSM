// vending_top.v  -  Top level for the Boolean board (Spartan-7 XC7S50)
//
//  BTN0 = coin Rs 5        SW0 (flip up) = pick item A (Rs 5)
//  BTN1 = coin Rs 10       SW1 (flip up) = pick item B (Rs 10)
//  BTN2 = cancel / refund  BTN3 = reset
//
//  LED0 = dispense A   LED1 = dispense B   LED2 = change returned
//  LED3 = refund       LED4 = warning (no coin / not enough credit)
//  LED7:5 = current state number (0 IDLE ... 4 REFUND)
//  Display D0 shows credit (or change while returning change)
module vending_top #(
    parameter integer DEBOUNCE_CYCLES = 2_000_000,
    parameter integer HOLD_CYCLES     = 200_000_000,
    parameter integer WARN_CYCLES     = 50_000_000,
    parameter         REVERSE_DIGITS  = 0
)(
    input  wire        clk,
    input  wire [3:0]  btn,
    input  wire [1:0]  sw,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [7:0]  seg
);
    reg r0 = 1'b0, r1 = 1'b0;
    always @(posedge clk) begin
        r0 <= btn[3];
        r1 <= r0;
    end
    wire rst = r1;

    wire coin5, coin10, cancel, pick_a, pick_b;
    wire u0, u1, u2, u3, u4;

    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) db_c5  (.clk(clk), .rst(rst), .noisy(btn[0]), .clean(u0), .rise(coin5));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) db_c10 (.clk(clk), .rst(rst), .noisy(btn[1]), .clean(u1), .rise(coin10));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) db_can (.clk(clk), .rst(rst), .noisy(btn[2]), .clean(u2), .rise(cancel));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) db_pa  (.clk(clk), .rst(rst), .noisy(sw[0]),  .clean(u3), .rise(pick_a));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) db_pb  (.clk(clk), .rst(rst), .noisy(sw[1]),  .clean(u4), .rise(pick_b));

    wire [2:0] state;
    wire [6:0] display_val;
    wire led_a, led_b, led_chg, led_ref, led_warn;

    vending_fsm #(.HOLD_CYCLES(HOLD_CYCLES), .WARN_CYCLES(WARN_CYCLES)) fsm (
        .clk(clk), .rst(rst),
        .coin5(coin5), .coin10(coin10),
        .pick_a(pick_a), .pick_b(pick_b), .cancel(cancel),
        .state(state), .display_val(display_val),
        .led_dispense_a(led_a), .led_dispense_b(led_b),
        .led_change(led_chg), .led_refund(led_ref), .led_warn(led_warn)
    );

    seg7_mux #(.REVERSE(REVERSE_DIGITS)) disp (
        .clk(clk), .value(display_val), .an(an), .seg(seg)
    );

    assign led = {8'b0, state, led_warn, led_ref, led_chg, led_b, led_a};
endmodule
