`default_nettype none

module alu(
input alu_op_t op,
input logic[15:0] alu_input1, alu_input2,
output logic[15:0] result);


always_comb
  unique case (op)
    ADD: result = $signed(alu_input1) + $signed(alu_input2);
    SUB: result = $signed(alu_input1) - $signed(alu_input2);
    SLL: result = alu_input1 << (alu_input2 & 16'h1F);
    SRL: result = alu_input1 >> (alu_input2 & 16'h1F);
    SRA: result = $signed(alu_input1) >>> (alu_input2 & 16'h1F);
    XOR: result = alu_input1 ^ alu_input2;
    OR: result = alu_input1 | alu_input2;
    AND: result = alu_input1 & alu_input2;
    default: result = 'bx;
  
  endcase
endmodule