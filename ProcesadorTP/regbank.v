module regfile (
    input  wire        clk,
    input  wire        nreset,      // Reset activo en bajo
    input  wire        reg_write,   // Habilitación de escritura (viene de decoder)
    
    // Direcciones de registros (5 bits cada una)
    input  wire [4:0]  rs1,         // Selección de registro para BUSA
    input  wire [4:0]  rs2,         // Selección de registro para BUSB
    input  wire [4:0]  rd,          // Selección de registro a escribir desde BUSC
    
    // Buses de Datos de 32 bits
    input  wire [31:0] BUSC,        // Dato a escribir en el registro 'rd' (desde ALU/Memoria)
    output wire [31:0] BUSA,        // Dato leído de 'rs1' (hacia ALU operand A)
    output wire [31:0] BUSB         // Dato leído de 'rs2' (hacia Mux / ALU operand B)
);

    // Array de 32 registros de 32 bits
    reg [31:0] registers [31:0];
    integer i;

    // --- LECTURA COMBINACIONAL ---
    // Si rs1 o rs2 apuntan a x0 (5'd0), se fuerza la salida a 0 en el bus correspondiente
    assign BUSA = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign BUSB = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // --- ESCRITURA SÍNCRONA ---
    always @(posedge clk or negedge nreset) begin
        if (!nreset) begin
            // Inicialización/Reset de los 32 registros a cero
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (reg_write && (rd != 5'd0)) begin
            // Escribe el contenido de BUSC en el registro 'rd' (siempre que rd != x0)
            registers[rd] <= BUSC;
        end
    end

endmodule