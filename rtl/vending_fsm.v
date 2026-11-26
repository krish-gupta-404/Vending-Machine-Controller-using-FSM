// vending_fsm.v
// Vending machine controller: 2 items (Rs 5, Rs 10), coins of Rs 5 and Rs 10.
// States: IDLE, COLLECT, DISPENSE, RETURN_CHANGE, REFUND.
// All inputs are one-clock pulses (already debounced).
module vending_fsm #(
    parameter [6:0] PRICE_A       = 7'd5,
    parameter [6:0] PRICE_B       = 7'd10,
    parameter integer HOLD_CYCLES = 200_000_000,  // 2 s at 100 MHz
    parameter integer WARN_CYCLES = 50_000_000    // 0.5 s warning LED
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       coin5,
    input  wire       coin10,
    input  wire       pick_a,
    input  wire       pick_b,
    input  wire       cancel,
    output reg  [2:0] state,
    output reg  [6:0] display_val,
    output wire       led_dispense_a,
    output wire       led_dispense_b,
    output wire       led_change,
    output wire       led_refund,
    output wire       led_warn
);
    localparam [2:0] IDLE          = 3'd0,
                     COLLECT       = 3'd1,
                     DISPENSE      = 3'd2,
                     RETURN_CHANGE = 3'd3,
                     REFUND        = 3'd4;

    reg [6:0]  credit = 7'd0;
    reg [6:0]  change = 7'd0;
    reg        item   = 1'b0;        // 0 = item A, 1 = item B
    reg [31:0] hold   = 32'd0;
    reg [31:0] warn   = 32'd0;

    initial state = IDLE;

    wire [7:0] add       = (coin5 ? 8'd5 : 8'd0) + (coin10 ? 8'd10 : 8'd0);
    wire [7:0] sum       = {1'b0, credit} + add;
    wire [6:0] sum_sat   = (sum > 8'd99) ? 7'd99 : sum[6:0];
    wire       hold_done = (hold == HOLD_CYCLES - 1);

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            credit <= 7'd0;
            change <= 7'd0;
            item   <= 1'b0;
            hold   <= 32'd0;
            warn   <= 32'd0;
        end else begin
            if (warn != 32'd0) warn <= warn - 32'd1;

            case (state)
                IDLE, COLLECT: begin
                    if (add != 8'd0) begin
                        credit <= sum_sat;
                        state  <= COLLECT;
                    end else if (pick_a) begin
                        if (credit >= PRICE_A) begin
                            item   <= 1'b0;
                            change <= credit - PRICE_A;
                            hold   <= 32'd0;
                            state  <= DISPENSE;
                        end else warn <= WARN_CYCLES;
                    end else if (pick_b) begin
                        if (credit >= PRICE_B) begin
                            item   <= 1'b1;
                            change <= credit - PRICE_B;
                            hold   <= 32'd0;
                            state  <= DISPENSE;
                        end else warn <= WARN_CYCLES;
                    end else if (cancel && credit != 7'd0) begin
                        hold  <= 32'd0;
                        state <= REFUND;
                    end
                end

                DISPENSE: begin
                    if (hold_done) begin
                        hold <= 32'd0;
                        if (change != 7'd0) state <= RETURN_CHANGE;
                        else begin
                            credit <= 7'd0;
                            state  <= IDLE;
                        end
                    end else hold <= hold + 32'd1;
                end

                RETURN_CHANGE: begin
                    if (hold_done) begin
                        hold   <= 32'd0;
                        credit <= 7'd0;
                        change <= 7'd0;
                        state  <= IDLE;
                    end else hold <= hold + 32'd1;
                end

                REFUND: begin
                    if (hold_done) begin
                        hold   <= 32'd0;
                        credit <= 7'd0;
                        state  <= IDLE;
                    end else hold <= hold + 32'd1;
                end

                default: state <= IDLE;
            endcase
        end
    end

    always @* begin
        if (state == RETURN_CHANGE) display_val = change;
        else                        display_val = credit;
    end

    assign led_dispense_a = (state == DISPENSE) && (item == 1'b0);
    assign led_dispense_b = (state == DISPENSE) && (item == 1'b1);
    assign led_change     = (state == RETURN_CHANGE);
    assign led_refund     = (state == REFUND);
    assign led_warn       = (warn != 32'd0);
endmodule
