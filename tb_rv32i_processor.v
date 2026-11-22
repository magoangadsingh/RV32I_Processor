
`timescale 1ns / 1ps

module tb_rv32i_processor;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;

    integer pass_count;
    integer fail_count;
    integer i;

    // =====================================
    // DUT: DEVICE UNDER TEST
    // =====================================

    rv32i_processor dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .instruction_out(instruction_out)
    );

    // =====================================
    // CLOCK GENERATION
    // =====================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // =====================================
    // INSTRUCTION ENCODING FUNCTIONS
    // =====================================

    function [31:0] enc_addi;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            enc_addi = {imm, rs1, 3'b000, rd, 7'b0010011};
        end
    endfunction

    function [31:0] enc_rtype;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        input sub;
        begin
            enc_rtype = {
                (sub ? 7'b0100000 : 7'b0000000),
                rs2, rs1, 3'b000, rd, 7'b0110011
            };
        end
    endfunction

    function [31:0] enc_sw;
        input [4:0] rs2;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            enc_sw = {
                imm[11:5], rs2, rs1, 3'b010,
                imm[4:0], 7'b0100011
            };
        end
    endfunction

    function [31:0] enc_lw;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            enc_lw = {imm, rs1, 3'b010, rd, 7'b0000011};
        end
    endfunction

    function [31:0] enc_beq;
        input [4:0] rs1;
        input [4:0] rs2;
        input [12:0] imm;
        begin
            enc_beq = {
                imm[12], imm[10:5], rs2, rs1,
                3'b000, imm[4:1], imm[11], 7'b1100011
            };
        end
    endfunction

    function [31:0] enc_jal;
        input [4:0] rd;
        input [20:0] imm;
        begin
            enc_jal = {
                imm[20], imm[10:1], imm[11],
                imm[19:12], rd, 7'b1101111
            };
        end
    endfunction

    // =====================================
    // RESULT CHECKING TASK
    // =====================================

    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;
        input [160*8-1:0] test_name;

        begin
            if (dut.register_file_inst.registers[reg_num]
                === expected) begin

                $display("PASS: %0s", test_name);
                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %0s | Expected=%h Actual=%h",
                    test_name,
                    expected,
                    dut.register_file_inst.registers[reg_num]
                );

                fail_count = fail_count + 1;

            end
        end
    endtask

    // =====================================
    // MAIN TEST SEQUENCE
    // =====================================

    initial begin

        reset = 1;
        pass_count = 0;
        fail_count = 0;

        // Load program into instruction memory

        dut.instruction_memory_inst.mem[0] =
            enc_addi(5'd1, 5'd0, 12'd10);

        dut.instruction_memory_inst.mem[1] =
            enc_addi(5'd2, 5'd0, 12'd20);

        dut.instruction_memory_inst.mem[2] =
            enc_rtype(5'd3, 5'd1, 5'd2, 1'b0);

        dut.instruction_memory_inst.mem[3] =
            enc_rtype(5'd4, 5'd2, 5'd1, 1'b1);

        dut.instruction_memory_inst.mem[4] =
            enc_sw(5'd3, 5'd0, 12'd0);

        dut.instruction_memory_inst.mem[5] =
            enc_lw(5'd5, 5'd0, 12'd0);

        dut.instruction_memory_inst.mem[6] =
            enc_beq(5'd3, 5'd5, 13'd8);

        // This instruction should be skipped
        dut.instruction_memory_inst.mem[7] =
            enc_addi(5'd6, 5'd0, 12'd99);

        dut.instruction_memory_inst.mem[8] =
            enc_addi(5'd7, 5'd0, 12'd7);

        dut.instruction_memory_inst.mem[9] =
            enc_jal(5'd8, 21'd8);

        // This instruction should be skipped
        dut.instruction_memory_inst.mem[10] =
            enc_addi(5'd9, 5'd0, 12'd55);

        dut.instruction_memory_inst.mem[11] =
            enc_addi(5'd10, 5'd0, 12'd42);

        // Stop execution in a self-loop
        dut.instruction_memory_inst.mem[12] =
            enc_jal(5'd0, 21'd0);

        // Apply reset for two clock cycles
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;

        // Execute the program
        repeat (11) @(posedge clk);

        #1;

        // =================================
        // REGISTER VERIFICATION
        // =================================

        $display("\n===== REGISTER TESTS =====");

        check_register(5'd1, 32'd10, "ADDI x1");
        check_register(5'd2, 32'd20, "ADDI x2");
        check_register(5'd3, 32'd30, "ADD x3");
        check_register(5'd4, 32'd10, "SUB x4");
        check_register(5'd5, 32'd30, "LW x5");
        check_register(5'd6, 32'd0, "BEQ skips x6");
        check_register(5'd7, 32'd7, "ADDI x7");
        check_register(5'd8, 32'd40, "JAL link address");
        check_register(5'd9, 32'd0, "JAL skips x9");
        check_register(5'd10, 32'd42, "ADDI x10");

        // =================================
        // MEMORY VERIFICATION
        // =================================

        $display("\n===== MEMORY TESTS =====");

        if (dut.data_memory_inst.mem[0] === 32'd30) begin
            $display("PASS: SW memory write");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: SW memory write");
            fail_count = fail_count + 1;
        end

        // =================================
        // PROGRAM COUNTER VERIFICATION
        // =================================

        $display("\n===== PC TESTS =====");

        if (pc_out === 32'd48) begin
            $display("PASS: Branch and jump PC execution");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: PC expected 48, got %d", pc_out);
            fail_count = fail_count + 1;
        end

        // =================================
        // FINAL SUMMARY
        // =================================

        $display("\n================================");
        $display("       PROCESSOR TEST SUMMARY");
        $display("================================");

        $display("Tests Passed : %0d", pass_count);
        $display("Tests Failed : %0d", fail_count);

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");

        $display("================================");

        $finish;

    end

endmodule
