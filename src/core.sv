`default_nettype none


//12 in 12 out
module cpu_core(
  input logic clk, rst,
  input logic ard_clk,
  input logic ard_data_ready, //could specify what kind of data send ard_instr, ard_data,
  input logic ard_receive_ready,
  input logic[7:0] in_bus,
  output logic bus_pc, bus_mar, bus_mdr, halt,
  output logic[7:0] out_bus
);


logic[15:0] alu_input1, alu_input2, alu_result;

logic valid_instr, error_instr;

logic[15:0] instr, mdr_in, mdr_out, mar_in, mar_out, pc;

logic[7:0] mdr_bus_out, mar_bus_out, pc_bus_out;

logic[15:0] pc_in, imm;

logic[15:0] rs1_data, rs2_data, rd_data;

ctrl_sig_t ctrl;

logic error_pc, error_mdr, error_mar, error_ctrl, reg_we;
dec_sig_t dec;
//declare components



control ctrl_fsm( .clk(ard_clk),
              .rst(rst),
              .ard_data_ready(ard_data_ready),
              .ard_receive_ready(ard_receive_ready),
              .signals(dec),
              .ctrl(ctrl),
              .bus_pc,
              .bus_mdr,
              .bus_mar,
              .error(error_ctrl),
              .halt(halt),
              .valid_instr(valid_instr));

instruction_decode dec_instr(.instruction(instr),
                              .signals(dec));

reg_file rf(.clk(ard_clk),
            .rst(rst),
            .rs1(dec.rs1),
            .rs2(dec.rs2),
            .rd(dec.rd),
            .rd_data(rd_data),
            .rs1_data(rs1_data),
            .rs2_data(rs2_data),
            .rd_we(reg_we));

instr_shift_register instr_shift( .clk(ard_clk),
                          .rst(rst),
                          .serial_in(in_bus),
                          .instruction(instr),
                          .imm(imm),
                          .valid(valid_instr),
                          .error(error_instr),
                          .data_ready(ard_data_ready),
                          .halt(halt));


alu alu(.alu_input1(alu_input1),
        .alu_input2(alu_input2),
        .op(dec.alu_op),
        .result(alu_result));

pc_shift_reg pc_reg(.clk(ard_clk),
                    .rst(rst),
                    .load(ctrl.pc_en),
                    .shift_out(ctrl.pc_shift_out),
                    .prll_in(pc_in),
                    .prll_out(pc),
                    .serial_out(pc_bus_out),
                    .error(error_pc));

eight_bit_spispo mdr_shift_reg(.clk(ard_clk),
                             .rst(rst),
                             .load(ctrl.mdr_load),
                             .shift_out(ctrl.mdr_shift_out),
                             .shift_in(ctrl.mdr_shift_in),
                             .serial_in(in_bus),
                             .prll_in(mdr_in),
                             .prll_out(mdr_out),
                             .serial_out(mdr_bus_out),
                             .error(error_mdr));

eight_bit_spispo mar_shift_reg(.clk(ard_clk),
                              .rst(rst),
                              .load(ctrl.mar_load),
                              .shift_out(ctrl.mar_shift_out),
                              .shift_in(1'b0),
                              .serial_in(8'b0),
                              .prll_in(mar_in),
                              .prll_out(mar_out),
                              .serial_out(mar_bus_out),
                              .error(error_mar));
always_comb begin
  case({bus_mar, bus_mdr, bus_pc})
    3'b001: out_bus = pc_bus_out;
    3'b010: out_bus = mdr_bus_out;
    3'b100: out_bus = mar_bus_out;
    default: out_bus = 'd0;
  endcase
end

//minor components

always_comb begin
  alu_input1 = rs1_data;
  alu_input2 = rs2_data;
  rd_data = alu_result;
  case(dec.opcode)
    R_TYPE: begin
      alu_input1 = rs1_data;
      alu_input2 = rs2_data;
      rd_data = alu_result;
    end
    I_TYPE: begin
      alu_input1 = rs1_data;
      alu_input2 = imm;
      rd_data = alu_result;
    end
    B_TYPE: begin
      alu_input1 = rs1_data;
      alu_input2 = rs2_data;
      rd_data = alu_result;
    end
    J_TYPE: begin
      alu_input1 = pc;
      alu_input2 = 4;
    end
    M_TYPE: begin
      if(dec.mem_op == LW | dec.mem_op == LB | dec.mem_op == LHW) begin
        alu_input1 = rs1_data;
        alu_input2 = imm;
        rd_data = mdr_out;
      end else if(dec.mem_op == SW | dec.mem_op == SB | dec.mem_op == SHW) begin
        alu_input1 = rs1_data;
        alu_input2 = imm;
      end
    end
  endcase

  mdr_in = (ard_data_ready) ? in_bus : rs2_data; // could be bus or register

  mar_in = alu_result;

  //3 cases, pc is set to value in jump, pc is pc + offset ( branch), pc is pc+4, double word
  case(dec.opcode)
    J_TYPE: pc_in = dec.addr_offset;
    B_TYPE: begin
      case(dec.b_type)
        BR_EQ: pc_in = (rs1_data == rs2_data) ? pc + dec.offset : pc + 1;
        BR_NE: pc_in = (rs1_data != rs2_data) ? pc + dec.offset : pc + 1;
        BR_LT: pc_in = ($signed(rs1_data) < $signed(rs2_data)) ? pc + dec.offset : pc + 1;
        BR_GE: pc_in = ($signed(rs1_data) >= $signed(rs2_data)) ? pc + dec.offset : pc + 1;
        BR_LTU: pc_in = (rs1_data < rs2_data) ? pc + dec.offset : pc + 1;
        BR_GEU: pc_in = (rs1_data >= rs2_data) ? pc + dec.offset : pc + 1;
        default: pc_in = pc + 1;
      endcase
    end
    I_TYPE: pc_in = pc + 2;
    M_TYPE: pc_in = pc + 2;
    default: pc_in = pc + 1;
  endcase

  // pc_offset = (dec.opcode == B_TYPE) ? dec.offset : 4; //jump will have pure address


  // pc_in = (dec.opcode == J_TYPE) ? dec.offset : pc + pc_offset;

  reg_we = (valid_instr & dec.rfWrite) ? 1'b1 : 1'b0;
end






endmodule
