module pc_target_calc (
    input  wire [31:0] currPC,      // Dirección actual del PC
    input  wire [31:0] busA,        // Dato leído de rs1 (BUSA desde el regfile)
    input  wire [31:0] imm,         // Inmediato decodificado y extendido en signo
    input  wire        is_jalr,     // Señal de control: 1 si es JALR, 0 si es Branch/JAL
    output wire [31:0] pc_target    // Dirección destino calculada para el MUX del PC
);

    wire [31:0] base_addr;

    // Si es JALR toma BUSA (R[rs1]), para Branch o JAL toma el PC actual
    assign base_addr = (is_jalr) ? busA : currPC;

    // Suma la base con el inmediato
    assign pc_target = base_addr + imm;

endmodule