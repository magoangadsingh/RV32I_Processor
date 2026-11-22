
module alu (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] alu_control,

    output reg [31:0] result,
    output wire zero
);

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_SLT = 4'b0101;

    always @(*) begin

        case (alu_control)

            ALU_ADD:
                result = operand_a + operand_b;

            ALU_SUB:
                result = operand_a - operand_b;

            ALU_AND:
                result = operand_a & operand_b;

            ALU_OR:
                result = operand_a | operand_b;

            ALU_XOR:
                result = operand_a ^ operand_b;

            ALU_SLT:
                result = ($signed(operand_a) < 
                          $signed(operand_b)) ? 32'd1 : 32'd0;

            default:
                result = 32'd0;

        endcase

    end

    assign zero = (result == 32'd0);

endmodule
