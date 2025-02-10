import Types::*;

typedef enum int {
  MSTATE_NULL,
  MSTATE_ADDR_OUT,
  MSTATE_LOAD_IR,
  MSTATE_EXEC
} mstate_t;

module ControlUnit (
    input logic clk,
    input logic rst,
    input logic [6:0] opcode,
    input bit stall,

    output cu_t active,

    output bit load_ir,
    output bit en_iaddr,
    output bit enable_pc_counter
);
  localparam cu_t null_cu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_mode: ALU_OP_FROM_F3,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC,
      pc_load: 0,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t aluimm = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FROM_F3,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      pc_load: 0,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t alu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_mode: ALU_OP_FROM_F3,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      pc_load: 0,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t load = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_MEM,
      pc_src: PC_SRC_NEXT_PC,
      pc_load: 0,
      dbus_we: 0,
      dbus_re: 1,
      en_comp_unit: 0
  };
  localparam cu_t store = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC,
      pc_load: 0,
      dbus_we: 1,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t branch = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_ALU,
      pc_load: 1'b1,
      dbus_we: 1'b0,
      dbus_re: 1'b0,
      en_comp_unit: 1
  };
  localparam cu_t jal = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU,
      pc_load: 1,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t jalr = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_mode: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU,
      pc_load: 1,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam cu_t lui = null_cu;
  localparam cu_t auipc = null_cu;



  mstate_t state, next_state;
  always_ff @(posedge clk, negedge rst) begin
    if (rst == 0) begin
      state <= MSTATE_NULL;
      next_state <= MSTATE_ADDR_OUT;
    end else begin
      if (stall) begin
        state <= state;
        next_state <= next_state;
        $display("Stalling!");
      end else begin
        state <= next_state;
        priority case (next_state)
          MSTATE_ADDR_OUT: next_state <= MSTATE_LOAD_IR;
          MSTATE_LOAD_IR: next_state <= MSTATE_EXEC;
          MSTATE_EXEC: next_state <= MSTATE_ADDR_OUT;
          default: next_state <= MSTATE_NULL;
        endcase
      end
    end
  end
  assign en_iaddr = state == MSTATE_ADDR_OUT || state == MSTATE_LOAD_IR;
  assign load_ir = state == MSTATE_LOAD_IR;
  assign enable_pc_counter = state == MSTATE_EXEC;

  always_comb begin
    case (opcode)
      OP_ALU:    active = alu;
      OP_ALUI:   active = aluimm;
      OP_LOAD:   active = load;
      OP_STORE:  active = store;
      OP_BRANCH: active = branch;
      OP_JAL:    active = jal;
      OP_JALR:   active = jalr;
      OP_LUI:    active = lui;
      OP_AUIPC:  active = auipc;
      default:   active = null_cu;
    endcase
    if (active == null_cu && state == MSTATE_EXEC) begin
      $fatal("Error executing opcode %07b", opcode);
    end
  end
`ifdef PRETTY_WAVETRACE
  alu_in_a_t P_alu_in_a;
  alu_in_b_t P_alu_in_b;
  alu_op_mode_t P_alu_mode;
  dest_reg_from_t P_dest_reg_from;
  pc_src_t P_pc_src;
  bit P_pc_load;
  bit P_dbus_we;
  bit P_dbus_re;
  assign P_alu_in_a = active.alu_in_a;
  assign P_alu_in_b = active.alu_in_b;
  assign P_alu_mode = active.alu_mode;
  assign P_dest_reg_from = active.dest_reg_from;
  assign P_pc_src = active.pc_src;
  assign P_pc_load = active.pc_load;
  assign P_dbus_we = active.dbus_we;
  assign P_dbus_re = active.dbus_re;
`endif
endmodule
