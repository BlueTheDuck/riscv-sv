import Types::*;

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
typedef struct packed {
  bit imm12;
  bit [5:0] imm10_5;
  bit [4:0] rs2;
  bit [4:0] rs1;
  bit [2:0] f3;
  bit [3:0] imm4_1;
  bit imm11;
  bit [6:0] op;
} op_b_t;
function automatic op_b_t op_b(bit [6:0] op, bit [2:0] f3, bit [4:0] rs1, bit [4:0] rs2, word imm);
  return op_b_t'{
    imm12: imm[12],
    imm11: imm[11],
    imm10_5: imm[10:5],
    imm4_1: imm[4:1],
    rs2: rs2,
    rs1: rs1,
    f3: f3,
    op: op
  };
endfunction

module CpuTb ();

  bit clk, rst;
  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ

  AvalonMmRw data_manager ();
  AvalonMmRead instruction_manager ();
  // Feed NOP; makes sure the CPU has something to read
  // We use cpu.execute_opcode to change the opcode
  assign instruction_manager.readdatavalid = 1;
  assign instruction_manager.agent_to_host = op_i_t'{
          imm: 0,
          rs1: 0,
          f3: 0,
          rd: 0,
          op: OP_ALUI
      };  // NOP

  Cpu cpu (
      .clk(clk),
      .rst(rst),
      .data_manager(data_manager.Host),
      .instruction_manager(instruction_manager.Host),
      .debug_current_pc(),
      .debug_instruction()
  );

  initial begin
    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, CpuTb);
    $display("Starting CPU Testbench...");
    fork
      begin
        test_core();
        test_math();
        test_jumps();
        test_branches();
        $display("All tests passed successfully.");
        #1 $finish;
      end
      #1000 begin
        $display("Testbench timed out, stopping simulation.");
        $finish;
      end
    join
  end

  task automatic test_core();
    $display("[%5t] Testing core functionality", $time);
  
    $display("[%5t] Assert initial reset", $time);
    reset();
    #1 assert (cpu.ir == 0)
    else $error("Assertion failed: expected ir == 0, but got %0d", cpu.ir);
    assert (cpu.current_pc == 0)
    else $error("Assertion failed: expected current_pc == 0, but got %0d", cpu.current_pc);
    assert (cpu.next_pc == 0)
    else $error("Assertion failed: expected next_pc == 0, but got %0d", cpu.next_pc);


    $display("[%5t] Assert reset after running", $time);
    repeat (10) @(posedge clk);
    reset();
    #1 assert (cpu.ir == 0)
    else $error("Assertion failed: expected ir == 0, but got %0d", cpu.ir);
    assert (cpu.current_pc == 0)
    else $error("Assertion failed: expected current_pc == 0, but got %0d", cpu.current_pc);
    assert (cpu.next_pc == 0)
    else $error("Assertion failed: expected next_pc == 0, but got %0d", cpu.next_pc);
  endtask

  task automatic test_math();
    $display("Doing test");
    cpu.execute_opcode(op_i_t
'{imm: 1, rs1: 10, f3: 0, rd: 11, op: OP_ALUI});  // x11 = x10 + 1
    cpu.regs.set_registers('{10: 4, default: 0});

    @(posedge clk);
    #1
      assert (cpu.regs.regs[11] == 0)
      else $error("Assertion failed: expected x11 == 0, but got %0d", cpu.regs.regs[11]);

    @(posedge clk);
    #1
      assert (cpu.regs.regs[11] == 5)
      else $error("Assertion failed: expected x11 == 5, but got %0d", cpu.regs.regs[11]);

    $display("Test passed: x11 is %0d", cpu.regs.regs[11]);
    $display("Test completed successfully.");
  endtask

  task automatic test_jumps();
    reset();
    $display("Testing jumps...");
    cpu.execute_opcode(op_i_t'{imm: 'hC, rs1: 0, f3: 0, rd: 0, op: OP_JALR});
    $display("[%04t] J 0xC", $time);
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.next_pc == 'hC)
      else $error("Assertion failed: expected next_pc == 0xC, but got 0x%08h", cpu.next_pc);
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.current_pc == 'hC)
      else $error("Assertion failed: expected current_pc == 0xC, but got 0x%08h", cpu.current_pc);
    @(posedge clk);

    cpu.execute_opcode(op_i_t'{imm: 'h18, rs1: 0, f3: 0, rd: 1, op: OP_JALR});
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.next_pc == 'h18)
      else $error("Assertion failed: expected next_pc == 0x18, but got 0x%08h", cpu.next_pc);
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.current_pc == 'h18)
      else
        $error(
            "Assertion failed: expected current_pc == 0x00000018, but got 0x%08h", cpu.current_pc
        );
    assert (cpu.regs.regs[1] == 'hC + 4)
    else $error("Assertion failed: expected x1 == 0xC, but got 0x%08h", cpu.regs.regs[1]);
  endtask

  task automatic test_branches();
    $display("[%4t] Testing branch instructions", $time);
    reset();
    $display("[%4t] BLTZ not taken", $time);
    cpu.regs.set_registers('{1: 5, default: 0});
    cpu.execute_opcode(op_b(
                       // BLTZ x1, +0xC
                       7'b1100011,
                       4,  // BLT
                       1,  // rs1
                       0,  // rs2
                       'hC  // imm
                       ));
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.next_pc == 'h4)
      else $error("Assertion failed: expected next_pc == 0x4, but got 0x%08h", cpu.next_pc);

    $display("[%4t] BLTZ taken", $time);
    cpu.execute_opcode(op_b(
                       // BGEZ x1, +0xC
                       7'b1100011,
                       'b101,  // BGE (~BLT)
                       1,  // rs1
                       0,  // rs2
                       'hC  // imm
                       ));
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.next_pc == 'h10)
      else $error("Assertion failed: expected next_pc == 0x10, but got 0x%08h", cpu.next_pc);


    $display("[%4t] BEQ taken", $time);
    cpu.execute_opcode(op_b(
                       // BEQZ, x2, 0xFFFFFFF0 (back to 0x0)
                       7'b1100011,
                       3'b000,  // BEQ
                       2,  // rs1
                       0,  // rs2
                       -16  // PC - 16 => next_pc = 0
                       ));
    @(posedge clk);
    @(posedge clk);
    #1
      assert (cpu.next_pc == 0)
      else $error("Assertion failed: expected next_pc == 0x0, but got 0x%08h", cpu.next_pc);

  endtask

  task automatic reset();
    $display("[%05t] Resetting CPU", $time);
    rst <= 1;
    #1;
    rst <= 0;
    @(posedge clk);
    rst <= 1;
  endtask
endmodule
