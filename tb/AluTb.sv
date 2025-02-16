`default_nettype none

import Types::*;

// TODO: maybe add this type to the main modules?
typedef struct packed {
  bit [6:0] f7;
  bit [4:0] rs2, rs1;
  bit [2:0] f3;
  bit [4:0] rd;
  bit [6:0] op;
} op_r_t;
typedef struct packed {
  bit [11:0] imm;
  bit [4:0]  rs1;
  bit [2:0]  f3;
  bit [4:0]  rd;
  bit [6:0]  op;
} op_i_t;
typedef union packed {
  op_i_t op_i;
  op_r_t op_r;
} op_t;

module AluTb ();
  op_t ir;
  word imm;
  bit [6:0] opcode;
  bit [2:0] f3;
  bit [6:0] f7;
  alu_mode_t alu_mode;
  tri alu_in_b_sel;
  word alu_in_a, alu_in_b, rs2_out;
  int out;

  assign alu_in_b_sel = ir.op_r.op == OP_ALU ? ALU_IN_B_REG : 'z;
  assign alu_in_b_sel = ir.op_i.op == OP_ALUI ? ALU_IN_B_IMM : 'z;
  Mux #(
      .INS(2)
  ) alu_input_b_selector (
      .sel(alu_in_b_sel),
      .in ('{rs2_out, imm}),
      .out(alu_in_b)
  );
  Decoder de (
      .ir(ir),
      .len(),
      .opcode(opcode),
      .rd(),
      .rs1(),
      .rs2(),
      .imm(imm),
      .f3(f3),
      .f7(f7)
  );
  ControlUnit cu (
      .clk(),
      .rst(),
      .opcode(opcode),
      .f3(f3),
      .f7(f7),
      .stall(),
      .active(),
      .alu_mode(alu_mode),
      .load_ir(),
      .en_iaddr(),
      .en_pc_counter()
  );
  Alu alu (
      .in_a(alu_in_a),
      .in_b(alu_in_b),
      .mode(alu_mode),
      .out (out)
  );

  initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, AluTb);
    cu.set_execute();
    fork
      doTest();
      #100 $finish;
    join
  end
  task automatic doTest();
    alu_in_a = 1;
    rs2_out  = 4;

    ir.op_i  = '{imm: 12'b010_0000_11111, rs1: 5'b0, f3: 3'b0, rd: 5'b0, op: OP_ALUI};
    #5;
    $display("%3d + %3d = %4d", alu_in_a, alu_in_b, out);
    #5;
    ir.op_r.op = OP_ALU;
    #5;
    $display("%3d - %3d = %4d", alu_in_a, alu_in_b, out);

    /* TEST Shift */
    #5;
    alu_in_a = (-15);
    rs2_out  = 3;


    #1 $display("SRLI");
    ir.op_i = '{imm: rs2_out, rs1: 0, f3: 5, rd: 0, op: OP_ALUI};
    #1 $display("%5d >>L %2d = %d", signed'(alu_in_a), rs2_out, out);

    #1 $display("SRAI");
    ir.op_i = '{imm: rs2_out | ('h20 << 5), rs1: 0, f3: 5, rd: 0, op: OP_ALUI};
    #1 $display("%5d >>A %2d = %d", signed'(alu_in_a), rs2_out, out);


    #1 $display("SRL");
    ir.op_r = '{f7: 0, rs2: 0, rs1: 0, f3: 5, rd: 0, op: OP_ALU};
    #1 $display("%5d >>L %2d = %d", signed'(alu_in_a), rs2_out, out);

    #1 $display("SRA");
    ir.op_r = '{f7: 'h20, rs2: 0, rs1: 0, f3: 5, rd: 0, op: OP_ALU};
    #1 $display("%5d >>A %2d = %d", signed'(alu_in_a), rs2_out, out);

  endtask  //automatic
endmodule
