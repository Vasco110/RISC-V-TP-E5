module jump_control (
    input  wire        branch,       // Viene del Decodificador (1 si es tipo BRANCH)
    input  wire        jump,         // Viene del Decodificador (1 si es JAL o JALR)
    input  wire [2:0]  funct3,       // Bits [14:12] de la instrucción
    input  wire        zero,         // Flag zero de la ALU (result == 0)
    input  wire        alu_result_msb, // Bit [31] del resultado de la ALU (indica si A - B < 0)
    
    output reg         take_branch   // 1: Se debe tomar el salto (cargar PC_target), 0: Continuar (PC + 4)
);

    reg branch_condition;

    always @(*) begin
        case (funct3)
            3'b000: branch_condition = zero;               // BEQ: Branch if Equal (A == B)
            3'b001: branch_condition = ~zero;              // BNE: Branch if Not Equal (A != B)
            3'b100: branch_condition = alu_result_msb;     // BLT: Branch if Less Than (con signo, A < B)
            3'b101: branch_condition = ~alu_result_msb;    // BGE: Branch if Greater or Equal (con signo, A >= B)
            3'b110: branch_condition = alu_result_msb;     // BLTU: Branch if Less Than Unsigned
            3'b111: branch_condition = ~alu_result_msb;    // BGEU: Branch if Greater or Equal Unsigned
            default: branch_condition = 1'b0;
        endcase
    end

    always @(*) begin
        // Se salta si es un Jump incondicional (JAL/JALR) O si es un Branch y se cumple su condición
        take_branch = jump | (branch & branch_condition);
    end

endmodule