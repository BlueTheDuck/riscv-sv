import Types::*;

module ControlUnit (
    input logic clk,
    input logic rst,
    input logic [6:0] opcode,
    input logic [2:0] f3,
    input logic [6:0] f7,

    input bit stall,

    output ins_ctrl_signals_t active,
    output alu_mode_t alu_mode,

    output bit load_ir,
    output bit en_iaddr,
    output bit en_pc_counter
);
  localparam ins_ctrl_signals_t null_cu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_op_from: ALU_OP_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t aluimm = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t alu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_op_from: ALU_OP_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t load = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_MEM,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 1,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t store = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 1,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t branch = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_ALU,
      dbus_we: 1'b0,
      dbus_re: 1'b0,
      en_comp_unit: 1
  };
  localparam ins_ctrl_signals_t jal = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t jalr = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t lui = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };
  localparam ins_ctrl_signals_t auipc = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC,
      dbus_we: 0,
      dbus_re: 0,
      en_comp_unit: 0
  };

  enum bit [1:0] {
    CU_STATE_NULL,
    CU_STATE_ADDR_OUT,
    CU_STATE_LOAD_IR,
    CU_STATE_EXEC
  } state, next_state;

  always_ff @(posedge clk, negedge rst) begin
    if (rst == 0) begin
      state <= CU_STATE_NULL;
      next_state <= CU_STATE_ADDR_OUT;
    end else begin
      if (stall) begin
        state <= state;
        next_state <= next_state;
      end else begin
        state <= next_state;
        priority case (next_state)
          CU_STATE_ADDR_OUT: next_state <= CU_STATE_LOAD_IR;
          CU_STATE_LOAD_IR: next_state <= CU_STATE_EXEC;
          CU_STATE_EXEC: next_state <= CU_STATE_ADDR_OUT;
          default: next_state <= CU_STATE_NULL;
        endcase
      end
    end
  end
  assign en_iaddr = state == CU_STATE_ADDR_OUT || state == CU_STATE_LOAD_IR;
  assign load_ir = state == CU_STATE_LOAD_IR;
  assign en_pc_counter = state == CU_STATE_EXEC;

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
    if (active == null_cu && state == CU_STATE_EXEC) begin
      $display("Error executing opcode %07b", opcode);
      $fatal;
    end
  end

  always_comb begin : ALU_OP_DECODER
    if (active.alu_op_from == ALU_OP_FIXED_ADD) begin
      alu_mode.operation = ALU_ADD;
    end else if (active.alu_op_from == ALU_OP_FROM_OPCODE) begin
      unique case (f3)
        0:
        if (opcode == OP_ALUI) alu_mode.operation = ALU_ADD;
        else if (opcode == OP_ALU) begin
          if (f7 == 'h00) alu_mode.operation = ALU_ADD;
          else if (f7 == 'h20) alu_mode.operation = ALU_SUB;
        end
        1: alu_mode.operation = ALU_SHIFT_LEFT_LOGICAL;
        2: begin
          alu_mode.operation = ALU_SET_LESS_THAN;
          alu_mode.signedness = SIGNED;
        end
        3: begin
          alu_mode.operation = ALU_SET_LESS_THAN;
          alu_mode.signedness = UNSIGNED;
        end
        4: alu_mode.operation = ALU_XOR;
        5:
        if (f7 == 'h00) alu_mode.operation = ALU_SHIFT_RIGHT_LOGICAL;
        else if (f7 == 'h20) alu_mode.operation = ALU_SHIFT_RIGHT_ARITHMETIC;
        6: alu_mode.operation = ALU_OR;
        7: alu_mode.operation = ALU_AND;
      endcase
    end else $fatal;
  end

  task automatic set_execute();
    state <= CU_STATE_EXEC;
  endtask

`ifdef PRETTY_WAVETRACE
  // verilator lint_off UNUSEDSIGNAL
  alu_in_a_t P_alu_in_a;
  alu_in_b_t P_alu_in_b;
  alu_op_from_t P_alu_op_from;
  dest_reg_from_t P_dest_reg_from;
  pc_src_t P_pc_src;
  bit P_dbus_we;
  bit P_dbus_re;
  assign P_alu_in_a = active.alu_in_a;
  assign P_alu_in_b = active.alu_in_b;
  assign P_alu_op_from = active.alu_op_from;
  assign P_dest_reg_from = active.dest_reg_from;
  assign P_pc_src = active.pc_src;
  assign P_dbus_we = active.dbus_we;
  assign P_dbus_re = active.dbus_re;
  // verilator lint_on UNUSEDSIGNAL
`endif
endmodule
