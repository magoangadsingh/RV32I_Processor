
module rv32i_processor (
    input wire clk,
    input wire reset,

    output wire [31:0] pc_out,
    output wire [31:0] instruction_out
);

    // =====================================
    // INTERNAL WIRES
    // =====================================

    wire [31:0] next_pc;
    wire [31:0] pc_plus4;

    wire [31:0] instruction;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    wire [31:0] immediate;

    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire alu_zero;

    wire [31:0] memory_read_data;
    wire [31:0] writeback_data;

    // Control signals
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire jump;

    wire [3:0] alu_control;

    wire branch_taken;

    // =====================================
    // 1. PROGRAM COUNTER
    // =====================================

    program_counter pc_inst (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc_out)
    );

    assign pc_plus4 = pc_out + 32'd4;

    // =====================================
    // 2. INSTRUCTION MEMORY
    // =====================================

    instruction_memory instruction_memory_inst (
        .address(pc_out),
        .instruction(instruction)
    );

    assign instruction_out = instruction;

    // =====================================
    // 3. REGISTER FILE
    // =====================================

    register_file register_file_inst (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),

        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),

        .write_data(writeback_data),

        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // =====================================
    // 4. IMMEDIATE GENERATOR
    // =====================================

    immediate_generator immediate_generator_inst (
        .instruction(instruction),
        .immediate(immediate)
    );

    // =====================================
    // 5. CONTROL UNIT
    // =====================================

    control_unit control_unit_inst (
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),

        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control)
    );

    // =====================================
    // 6. ALU
    // =====================================

    assign alu_operand_b =
        (alu_src) ? immediate : read_data2;

    alu alu_inst (
        .operand_a(read_data1),
        .operand_b(alu_operand_b),
        .alu_control(alu_control),

        .result(alu_result),
        .zero(alu_zero)
    );

    // =====================================
    // 7. DATA MEMORY
    // =====================================

    data_memory data_memory_inst (
        .clk(clk),
        .reset(reset),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(alu_result),
        .write_data(read_data2),

        .read_data(memory_read_data)
    );

    // =====================================
    // 8. WRITEBACK LOGIC
    // =====================================

    assign writeback_data =
        jump       ? pc_plus4 :
        mem_to_reg ? memory_read_data :
                     alu_result;

    // =====================================
    // 9. NEXT PC LOGIC
    // =====================================

    assign branch_taken = branch & alu_zero;

    assign next_pc =
        jump        ? (pc_out + immediate) :
        branch_taken ? (pc_out + immediate) :
                       pc_plus4;

endmodule
