package Types;
  typedef bit [31:0] word;

  typedef enum bit [6:0] {
    OP_ALU    = 7'b0110011,
    OP_ALUI   = 7'b0010011,
    OP_LOAD   = 7'b0000011,
    OP_STORE  = 7'b0100011,
    OP_BRANCH = 7'b1100011,
    OP_JAL    = 7'b1101111,
    OP_JALR   = 7'b1100111,
    OP_LUI    = 7'b0110111,
    OP_AUIPC  = 7'b0010111
  } opcode_t;

  typedef struct packed {
    bit mode, un, neg;
  } comparison_op_t;

  typedef enum bit {
    ALU_IN_A_REG = 1'b0,
    ALU_IN_A_PC
  } alu_in_a_t;
  typedef enum bit {
    ALU_IN_B_REG = 1'b0,
    ALU_IN_B_IMM
  } alu_in_b_t;
  typedef enum bit {
    ALU_OP_FROM_F3   = 1'b0,
    ALU_OP_FIXED_ADD
  } alu_op_mode_t;
  typedef enum bit [1:0] {
    DEST_REG_FROM_NONE = 2'b0,
    DEST_REG_FROM_ALU,
    DEST_REG_FROM_MEM,
    DEST_REG_FROM_PC
  } dest_reg_from_t;
  typedef enum bit {
    PC_SRC_NEXT_PC = 1'b0,
    PC_SRC_ALU
  } pc_src_t;

  typedef struct packed {
    alu_in_a_t alu_in_a;
    alu_in_b_t alu_in_b;
    alu_op_mode_t alu_mode;
    dest_reg_from_t dest_reg_from;
    pc_src_t pc_src;
    bit pc_load;
    bit dbus_we, dbus_re;
    bit en_comp_unit;
  } cu_t;
endpackage
