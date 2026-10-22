module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,  // {funct7[5], funct3}
    output reg  [31:0] result,
    output wire        zero
);

    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b;                                      // ADD / ADDI
            4'b1000: result = a - b;                                      // SUB
            4'b0001: result = a << b[4:0];                                // SLL / SLLI
            4'b0010: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT / SLTI
            4'b0011: result = (a < b) ? 32'd1 : 32'd0;                 // SLTU / SLTIU
            4'b0100: result = a ^ b;                                      // XOR / XORI
            4'b0101: result = a >> b[4:0];                                // SRL / SRLI
            4'b1101: result = $signed(a) >>> b[4:0];                      // SRA / SRAI
            4'b0110: result = a | b;                                      // OR / ORI
            4'b0111: result = a & b;                                      // AND / ANDI
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule