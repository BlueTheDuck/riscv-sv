`define KB(n) (n * 1024)

module Computer ();
  bit clk, rst;
  AvalonMmRead ibus ();
  AvalonMmRw dbus ();
  AvalonMmRw bus ();
  CrossBar xbar (
      .clk(clk),
      .bus_side(bus.Host),
      .instruction_manager(ibus.Agent),
      .data_manager(dbus.Agent)
  );
  Memory #(
      .BASE(0),
      .SIZE(`KB(16)),
      .INIT_FILE("rom.bin"),
      .DUMP_FILE("ram.hexdump"),
      .READ_ONLY(0)
  ) memory (
      .bus(bus.Agent),
      .*
  );
  Cpu cpu (
      .clk(clk),
      .rst(rst),
      .instruction_manager(ibus.Host),
      .data_manager(dbus.Host),
      .*
  );

  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ
  always_ff @(posedge clk, negedge rst) begin
    cpu.dump_state();
  end
  initial rst = 1;

  initial begin
    $dumpfile("trace.vcd");
    $dumpvars(0, Computer);
    fork
      doTest();
      #1000 $finish;
    join
  end
  task automatic doTest();
    cpu.dump_state();
    #5 rst = 1;
    #9 rst = 0;
    #7 rst = 1;
    $display("Reset done");
  endtask  //automatic
  task automatic tick();
`ifdef DEBUG
    cpu.dump_state();
`endif
  endtask  //automatic
endmodule
