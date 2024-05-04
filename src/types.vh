

// Constants that specify which operation the ALU should perform
`ifndef TYPES
`define TYPES
  typedef enum logic {
    JAL = 'b0,
    JALR = 'b1
  } jmp_t;


  typedef enum logic [2:0] {
      R_TYPE = 3'b000,
      I_TYPE = 3'b001,
      B_TYPE = 3'b010,
      J_TYPE = 3'b011,
      M_TYPE = 3'b100,
      NOP_TYPE = 3'b101,
      SYS_END = 3'b110
  } opcode_t;

  typedef enum logic[3:0] {
      LB = 3'b000,
      LHW = 3'b001,
      LW = 3'b010,
      LS_NONE = 3'b011,
      SB = 3'b100,
      SHW = 3'b101,
      SW = 3'b110
  } mem_op_t;


  typedef enum logic[2:0] {
      BR_EQ,
      BR_NE,
      BR_LT,
      BR_GE,
      BR_LTU,
      BR_GEU,
      BR_NONE
  } br_op_t;

  typedef enum logic[3:0] {
      ADD = 4'b0000,
      SUB = 4'b0001,
      OR = 4'b0010, 
      XOR = 4'b0011,
      SLL = 4'b0100,
      SRL = 4'b0101, 
      SRA = 4'b0110,
      AND = 4'b0111
  } alu_op_t;

  typedef struct packed {
    opcode_t opcode;
    logic[2:0] rs1;
    logic[2:0] rs2;
    logic[2:0] rd;
    logic is_double_word;
    logic rfWrite;
    mem_op_t mem_op;
    br_op_t br_op;
    logic[3:0] offset;
    logic[8:0] addr_offset;
    logic useImm;
    logic useAddr;
    alu_op_t alu_op;
    br_op_t b_type;
    jmp_t jump_type;
  } dec_sig_t;

  typedef struct packed {
    logic go;
    logic instr_shift_in;
    logic mdr_shift_out;
    logic mar_shift_out;
    logic mdr_shift_in;
    logic pc_shift_out;
    logic shift_done;
    logic mdr_load;
    logic mar_load;
    logic pc_en;
  } ctrl_sig_t;

  `endif