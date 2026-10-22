module reg32
(
    input[31:0] d,
    input clk,
    input nreset,
    input ena,
    output [31:0] qo
);

    reg[31:0] q;
    wire reset;

    //assign reset = ~nreset;

    always @(posedge clk, negedge nreset) begin
        if (~nreset) begin
            q <= 0;
        end
        else if (clk && ena) begin
            q <= d;
        end
    end

    assign qo = q;

endmodule