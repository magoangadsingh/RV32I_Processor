
module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,

    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [3:0] alu_control
);

    // ALU operation codes
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;

    // Instruction opcodes
    localparam OP_RTYPE = 7'b0110011;
    localparam OP_ITYPE = 7'b0010011;
    localparam OP_LOAD  = 7'b0000011;
    localparam OP_STORE = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL   = 7'b1101111;

    always @(*) begin

        // Default control signals
        reg_write = 0;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        alu_control = ALU_ADD;

        case (opcode)

            // R-Type: ADD and SUB
            OP_RTYPE: begin

                reg_write = 1;
                alu_src = 0;

                if (funct3 == 3'b000 &&
                    funct7 == 7'b0100000)
                    alu_control = ALU_SUB;
                else
                    alu_control = ALU_ADD;

            end

            // I-Type: ADDI
            OP_ITYPE: begin

                reg_write = 1;
                alu_src = 1;
                alu_control = ALU_ADD;

            end

            // LW
            OP_LOAD: begin

                reg_write = 1;
                alu_src = 1;
                mem_read = 1;
                mem_to_reg = 1;
                alu_control = ALU_ADD;

            end

            // SW
            OP_STORE: begin

                alu_src = 1;
                mem_write = 1;
                alu_control = ALU_ADD;

            end

            // BEQ
            OP_BRANCH: begin

                branch = 1;
                alu_src = 0;
                alu_control = ALU_SUB;

            end

            // JAL
            OP_JAL: begin

                reg_write = 1;
                jump = 1;
                alu_control = ALU_ADD;

            end

            default: begin
                // Unsupported instruction
            end

        endcase

    end

endmodule
