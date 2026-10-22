module decoder (
    input  wire [31:0] instr,           // Instrucción completa de 32 bits desde IF
    
    // Extracción de campos directos de la instrucción
    output wire [6:0]  opcode,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    
    // Inmediato decodificado y extendido a 32 bits
    output reg  [31:0] imm,
    
    // Señales de control del Datapath
    output reg         reg_write,   // Habilita escritura en Banco de Registros
    output reg         alu_src,     // 0: operando B es rs2, 1: operando B es Inmediato
    output reg  [3:0] alu_control, // {funct7[5], funct3} -> Código optimizado directo
    output reg         mem_read,    // Habilita lectura de Memoria de Datos (LOAD)
    output reg         mem_write,   // Habilita escritura en Memoria de Datos (STORE)
    output reg         mem_to_reg,  // 0: escribe resultado de ALU, 1: escribe dato de Memoria
    output reg         branch,      // Señal de salto condicional (BEQ, BNE, BLT, BGE, etc.)
    output reg         jump,        // Señal de salto incondicional (JAL, JALR)
    output reg         is_jalr      // 1: dirección base es BUSA (rs1), 0: dirección base es currPC
);

    // 1. Extraer campos fijos de la instrucción
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // 2. Decodificación de Inmediatos con extensión de signo según formato
    always @(*) begin
        case (opcode)
            7'b0010011, // OP-IMM (I-type)
            7'b0000011, // LOAD (I-type)
            7'b1100111: // JALR (I-type)
                imm = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: // STORE (S-type)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // BRANCH (B-type)
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

            7'b0110111, // LUI (U-type)
            7'b0010111: // AUIPC (U-type)
                imm = {instr[31:12], 12'b0};

            7'b1101111: // JAL (J-type)
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            default: 
                imm = 32'd0;
        endcase
    end

    // 3. Generación de Señales de Control Principales
    always @(*) begin
        // Valores por defecto (evita latches indeseados)
        reg_write   = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        is_jalr     = 1'b0;

        case (opcode)
            // OPERACIONES DE REGISTRO TIPO R (OP: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
            7'b0110011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b0; // Usa rs2
                // Mapeo directo de 4 bits: bit 30 (funct7[5]) + bits 14:12 (funct3)
                alu_control = {instr[30], instr[14:12]};
            end

            // OPERACIONES CON INMEDIATO TIPO I (OP-IMM: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1; // Usa Inmediato
                
                // Para desplazamientos inmediatos (SLLI, SRLI, SRAI), el bit 30 diferencia SRLI de SRAI.
                // Para las demás (ADDI, ANDI, etc.), forzamos el bit MSB a 0.
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    alu_control = {instr[30], instr[14:12]};
                else
                    alu_control = {1'b0, instr[14:12]};
            end

            // LOAD (LW, LH, LB, LHU, LBU)
            7'b0000011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;     // Dirección = rs1 + imm
                alu_control = 4'b0000;  // Suma (ADD)
                mem_read    = 1'b1;
                mem_to_reg  = 1'b1;     // Escribe dato leído de memoria
            end

            // STORE (SW, SH, SB)
            7'b0100011: begin
                alu_src     = 1'b1;     // Dirección = rs1 + imm
                alu_control = 4'b0000;  // Suma (ADD)
                mem_write   = 1'b1;
            end

            // BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b1100011: begin
                branch      = 1'b1;
                alu_control = 4'b1000;  // Resta (SUB) para comparar rs1 y rs2
            end

            // JAL
            7'b1101111: begin
                reg_write   = 1'b1;     // Guarda PC+4 en rd
                jump        = 1'b1;
            end

            // JALR
            7'b1100111: begin
                reg_write   = 1'b1;     // Guarda PC+4 en rd
                jump        = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;  // Suma base + offset
                is_jalr     = 1'b1;     // Indica que el salto toma BUSA (rs1) como base
            end

            // LUI
            7'b0110111: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;  // Pasa el inmediato directamente
            end

            default: begin
                // Mantiene señales deshabilitadas por defecto
            end
        endcase
    end

endmodule