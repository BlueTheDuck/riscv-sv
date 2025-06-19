module ControlUnit (
    input bit clk,
    input bit rst,
    input bit [6:0] opcode,
    input bit [2:0] f3,
    input bit [6:0] f7,

    input bit stall,

    output Types::data_path_map_t data_path,
    output Types::alu_mode_t alu_mode,
    output bit invert_logic_result,
    output bit dbus_we,
    output bit is_branch,

    output bit fetch_next_instruction,
    output bit load_ir,
    output bit en_pc_counter,
    output bit write_back_stage
);
  import Types::*;

  localparam data_path_map_t null_cu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t aluimm = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_ARITHMETIC_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t alu = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_op_from: ALU_OP_ARITHMETIC_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t load = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_MEM,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t store = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t branch = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_REG,
      alu_op_from: ALU_OP_LOGIC_FROM_OPCODE,
      dest_reg_from: DEST_REG_FROM_NONE,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t jal = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU
  };
  localparam data_path_map_t jalr = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_PC,
      pc_src: PC_SRC_ALU
  };
  localparam data_path_map_t lui = '{
      alu_in_a: ALU_IN_A_REG,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC
  };
  localparam data_path_map_t auipc = '{
      alu_in_a: ALU_IN_A_PC,
      alu_in_b: ALU_IN_B_IMM,
      alu_op_from: ALU_OP_FIXED_ADD,
      dest_reg_from: DEST_REG_FROM_ALU,
      pc_src: PC_SRC_NEXT_PC
  };

  comparison_op_t comp_op;


  enum int {
    CU_STATE_NULL,
    CU_STATE_ADDR_OUT,
    CU_STATE_LOAD_IR,
    CU_STATE_EXEC,
    CU_STATE_WRITEBACK
  } state;

  initial state = CU_STATE_NULL;

  always_ff @(posedge clk, negedge rst) begin
    if (rst == 0) begin
      state <= CU_STATE_NULL;
    end else begin
      if (stall) begin
        state <= state;
      end else begin : STATE_MACHINE
        priority case (state)
          CU_STATE_ADDR_OUT: state <= CU_STATE_LOAD_IR;
          CU_STATE_LOAD_IR: state <= CU_STATE_EXEC;
          CU_STATE_EXEC: state <= CU_STATE_WRITEBACK;
          CU_STATE_WRITEBACK: state <= CU_STATE_ADDR_OUT;
          default: state <= CU_STATE_ADDR_OUT;
        endcase
      end
    end
  end
  assign fetch_next_instruction = state == CU_STATE_ADDR_OUT || state == CU_STATE_LOAD_IR;
  assign load_ir = state == CU_STATE_LOAD_IR;
  assign en_pc_counter = state == CU_STATE_EXEC;
  assign write_back_stage = state == CU_STATE_WRITEBACK;

  always_comb begin
    case (opcode)
      OP_ALU:    data_path = alu;
      OP_ALUI:   data_path = aluimm;
      OP_LOAD:   data_path = load;
      OP_STORE:  data_path = store;
      OP_BRANCH: data_path = branch;
      OP_JAL:    data_path = jal;
      OP_JALR:   data_path = jalr;
      OP_LUI:    data_path = lui;
      OP_AUIPC:  data_path = auipc;
      default:   data_path = null_cu;
    endcase
    if (data_path == null_cu && state == CU_STATE_EXEC) begin
      $display("Error executing opcode %07b", opcode);
      $fatal;
    end
  end

  // Special cases
  assign dbus_we = opcode == OP_STORE;
  assign is_branch  = opcode == OP_BRANCH;
  assign comp_op = f3;

  always_comb begin : ALU_OP_DECODER
    if (data_path.alu_op_from == ALU_OP_FIXED_ADD) begin
      alu_mode.operation = ALU_ADD;
    end else if (data_path.alu_op_from == ALU_OP_ARITHMETIC_FROM_OPCODE) begin
      unique case (f3)
        0:
        if (opcode == OP_ALU && f7 == 'h20) alu_mode.operation = ALU_SUB;
        else alu_mode.operation = ALU_ADD;
        1: alu_mode = '{operation: ALU_SHIFT_LEFT, signedness: UNSIGNED};
        2: alu_mode = '{operation: ALU_SET_LESS_THAN, signedness: SIGNED};
        3: alu_mode = '{operation: ALU_SET_LESS_THAN, signedness: UNSIGNED};
        4: alu_mode.operation = ALU_XOR;
        5:
        priority casez (f7)
          7'b00?????: alu_mode = '{operation: ALU_SHIFT_RIGHT, signedness: UNSIGNED};
          7'b01?????: alu_mode = '{operation: ALU_SHIFT_RIGHT, signedness: SIGNED};
          default: $fatal;
        endcase
        6: alu_mode.operation = ALU_OR;
        7: alu_mode.operation = ALU_AND;
      endcase
    end else if (data_path.alu_op_from == ALU_OP_LOGIC_FROM_OPCODE) begin
      if (comp_op.mode == 1'b0) begin
        alu_mode.operation = ALU_EQ;
      end else begin
        alu_mode = '{
            operation: ALU_SET_LESS_THAN,
            signedness: (comp_op.unsignedness == 0) ? SIGNED : UNSIGNED
        };
      end
      invert_logic_result = comp_op.negate;
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
  assign P_alu_in_a = data_path.alu_in_a;
  assign P_alu_in_b = data_path.alu_in_b;
  assign P_alu_op_from = data_path.alu_op_from;
  assign P_dest_reg_from = data_path.dest_reg_from;
  assign P_pc_src = data_path.pc_src;
  assign P_dbus_we = data_path.dbus_we;
  // verilator lint_on UNUSEDSIGNAL
`endif
endmodule
