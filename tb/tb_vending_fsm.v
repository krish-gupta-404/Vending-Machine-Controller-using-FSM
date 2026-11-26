`timescale 1ns/1ps
// Self-checking testbench for vending_fsm (short timers so it runs fast).
module tb_vending_fsm;
    localparam HOLD = 20, WARN = 10;
    reg clk = 0, rst = 1;
    reg coin5 = 0, coin10 = 0, pick_a = 0, pick_b = 0, cancel = 0;
    wire [2:0] state;
    wire [6:0] display_val;
    wire led_a, led_b, led_chg, led_ref, led_warn;
    integer errors = 0;

    vending_fsm #(.HOLD_CYCLES(HOLD), .WARN_CYCLES(WARN)) dut (
        .clk(clk), .rst(rst), .coin5(coin5), .coin10(coin10),
        .pick_a(pick_a), .pick_b(pick_b), .cancel(cancel),
        .state(state), .display_val(display_val),
        .led_dispense_a(led_a), .led_dispense_b(led_b),
        .led_change(led_chg), .led_refund(led_ref), .led_warn(led_warn));

    always #5 clk = ~clk;

    task pulse_coin5;  begin coin5  = 1; @(posedge clk); #1 coin5  = 0; end endtask
    task pulse_coin10; begin coin10 = 1; @(posedge clk); #1 coin10 = 0; end endtask
    task pulse_a;      begin pick_a = 1; @(posedge clk); #1 pick_a = 0; end endtask
    task pulse_b;      begin pick_b = 1; @(posedge clk); #1 pick_b = 0; end endtask
    task pulse_cancel; begin cancel = 1; @(posedge clk); #1 cancel = 0; end endtask
    task wait_hold;    begin repeat (HOLD) @(posedge clk); #1; end endtask

    task check;
        input cond;
        input [8*44-1:0] msg;
        begin
            if (cond) $display("PASS: %0s", msg);
            else begin
                $display("FAIL: %0s (state=%0d disp=%0d)", msg, state, display_val);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk); #1 rst = 0;
        check(state == 0 && display_val == 0, "reset -> IDLE, display 0");

        pulse_coin10;
        check(state == 1 && display_val == 10, "coin10 -> COLLECT, credit 10");
        pulse_a;
        check(state == 2 && led_a && !led_b, "pick A -> DISPENSE, LED A");
        wait_hold;
        check(state == 3 && led_chg && display_val == 5, "RETURN_CHANGE shows 5");
        wait_hold;
        check(state == 0 && display_val == 0, "back to IDLE, credit 0");

        pulse_coin10;
        pulse_b;
        check(state == 2 && led_b && !led_a, "pick B -> DISPENSE, LED B");
        wait_hold;
        check(state == 0 && display_val == 0, "exact pay -> IDLE, no change");

        pulse_coin5;
        pulse_b;
        check(state == 1 && led_warn, "item B with Rs5 -> warning, stay COLLECT");
        pulse_cancel;
        check(state == 4 && led_ref && display_val == 5, "cancel -> REFUND shows 5");
        wait_hold;
        check(state == 0 && display_val == 0, "refund done -> IDLE");

        pulse_a;
        check(state == 0 && led_warn, "pick with no coin -> warning");

        pulse_coin5; pulse_coin5; pulse_coin5;
        check(display_val == 15, "three Rs5 coins -> credit 15");
        pulse_a;
        pulse_coin10;
        check(state == 2, "coin during DISPENSE ignored");
        wait_hold;
        check(state == 3 && display_val == 10, "change Rs10 returned");
        wait_hold;
        check(state == 0, "IDLE again");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
