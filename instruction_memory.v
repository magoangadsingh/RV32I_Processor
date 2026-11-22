
module instruction_memory (
    input wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:255];
    integer i;

    // Initialize instruction memory with NOP instructions
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;

        // Program used for processor verification
        mem[0]  = 32'h00A00093; // ADDI x1, x0, 10
        mem[1]  = 32'h01400113; // ADDI x2, x0, 20
        mem[2]  = 32'h002081B3; // ADD  x3, x1, x2
        mem[3]  = 32'h40110233; // SUB  x4, x2, x1
        mem[4]  = 32'h00302023; // SW   x3, 0(x0)
        mem[5]  = 32'h00002283; // LW   x5, 0(x0)
        mem[6]  = 32'h00518463; // BEQ  x3, x5, 8
        mem[7]  = 32'h06300313; // ADDI x6, x0, 99 (skipped)
        mem[8]  = 32'h00700393; // ADDI x7, x0, 7
        mem[9]  = 32'h0080046F; // JAL  x8, 8
        mem[10] = 32'h03700493; // ADDI x9, x0, 55 (skipped)
        mem[11] = 32'h02A00513; // ADDI x10, x0, 42
        mem[12] = 32'h0000006F; // JAL  x0, 0 (self-loop)
    end

    // Word-aligned instruction addressing
    assign instruction = mem[address[9:2]];

endmodule
