module fetch(
    input wire [31:0] currPC,
    output wire [31:0] nextPC,
    input wire [31:0] memOpcode,
    output wire [31:0] outOpcode
);

    assign nextPC = currPC + 4;
    assign outOpcode = memOpcode;

endmodule