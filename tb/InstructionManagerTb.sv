typedef struct packed {
  bit [11:0] imm;
  bit [4:0]  rs1;
  bit [2:0]  f3;
  bit [4:0]  rd;
  bit [6:0]  op;
} op_i_t;

module InstructionManagerTb ();
  import Types::*;

  bit clk, rst;
  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ

  AvalonMmRw data_manager ();
  AvalonMmRead im ();
  assign im.byteenable = 4'b1111;

  InstructionManagerUnit dut (
      .clk(clk),
      .rst(rst),
      .instruction_manager(im.Host),
      .pc(),
      .fetch_next_instruction(),
      .ready(),
      .ir()
  );

  initial begin
    $dumpfile("instruction_manager_tb.vcd");
    $dumpvars(0, InstructionManagerTb);
    $display("Starting Instruction Manager Testbench...");


    $display("Test: Instruction Manager works under normal conditions");

    rst = 0;
    im.waitrequest = 1;
    im.readdatavalid = 0;
    #1;
    rst = 1;

    dut.pc = 0;
    dut.fetch_next_instruction = 1;
  
    @(posedge clk);


    #1
    assert (dut.state == 1 && im.read == 1)
    else $fatal("CU not in fetch state after reset");
    
    dut.fetch_next_instruction = 0;

    // As long as waitrequest is high, the CPU should keep the request on the bus
    @(posedge clk);

    #1
    assert (im.read == 1 && im.address == 0)
    else $fatal("CPU did not keep read request on bus when waitrequest is high");

    @(posedge clk);

    #1
    assert (im.read == 1 && im.address == 0)
    else $fatal("CPU did not keep read request on bus when waitrequest is high");

    // Stop waitrequest, but do not set readdatavalid yet

    im.waitrequest = 0;

    @(posedge clk);
    
    #1
    assert (im.read == 0)
    else $fatal("CPU did not stop read request when waitrequest is low; this would be interpreted as a second request");

    @(posedge clk);

    #1
    assert (im.read == 0)
    else $fatal("CPU did not stop read request when waitrequest is low; this would be interpreted as a second request");
  
    @(posedge clk);

    im.readdatavalid = 1;
    im.agent_to_host = 32'hdeadbeef; // Simulate a read response

    @(posedge clk);

    #1
    assert (dut.state == 0 && dut.ir == 32'hdeadbeef && dut.ready == 1)
    else $fatal("CPU did not read data from bus correctly");

    #3 $finish;
  end

  task automatic reset();
    $display("[%05t] Resetting", $time);
    rst = 1;
    #1;
    rst = 0;
    @(posedge clk);
    rst = 1;
  endtask
endmodule
