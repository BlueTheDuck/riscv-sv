typedef struct packed {
  bit [11:0] imm;
  bit [4:0]  rs1;
  bit [2:0]  f3;
  bit [4:0]  rd;
  bit [6:0]  op;
} op_i_t;

module DataManagerTb ();
  import Types::*;

  bit clk, rst;
  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ

  AvalonMmRw bus ();

  MemoryUnit dut (
      .clk(clk),
      .rst(rst),

      .address(),
      .size(),
      .zero_extend(),
      
      .read(),
      .from_bus(),
      
      .write(),
      .to_bus(),
      
      .ready(),

      .port(bus.Host)
  );

  initial begin
    $dumpfile("data_manager_tb.vcd");
    $dumpvars(0, DataManagerTb);
    $display("Starting Data Manager Testbench...");

    test_read_words_happy();
    test_read_halfwords_bytes_unsigned();
    test_read_halfwords_bytes_sign_extend();

    #3 $finish;
  end

  task automatic test_read_words_happy();
    $display("Test: Data Manager can read words normally");

    reset();

    dut.address = 0;
    dut.read = 1;
    dut.size = INT_SIZE_WORD;

    @(posedge clk);


    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b1111)
    else $fatal("Data manager not putting request on bus");

    bus.waitrequest = 1;

    // As long as waitrequest is high, the CPU should keep the request on the bus
    @(posedge clk);

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b1111)
    else $fatal("Data manager not putting request on bus (Waitrequest 1/2)");

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b1111)
    else $fatal("Data manager not putting request on bus (Waitrequest 2/2)");

    bus.waitrequest = 0;

    @(posedge clk);
    
    #1
    assert (bus.read == 0)
    else $fatal("CPU did not stop read request when waitrequest is low; this would be interpreted as a second request");

    bus.readdatavalid = 1;
    bus.agent_to_host = 32'hDEADBEEF;

    @(posedge clk);

    #1
    assert (dut.from_bus == 32'hDEADBEEF && dut.ready == 1)
    else $fatal("CPU did not read data from bus correctly");
  endtask

  task automatic test_read_halfwords_bytes_unsigned();
    // Test uint16_t, uint8_t, int16_t and int8_t
    //
    $display("Test: Data Manager can read halfwords and bytes, zero extends them");

    reset();

    dut.address = 0;
    dut.read = 1;
    dut.size = INT_SIZE_HALF;

    @(posedge clk);

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b0011)
    else $fatal("Data Manager did not put correct request on bus");

    bus.waitrequest = 1;

    // As long as waitrequest is high, the CPU should keep the request on the bus
    @(posedge clk);

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b0011)
    else $fatal("Data Manager did not hold the request on bus (Waitrequest 1/2)");

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b0011)
    else $fatal("Data Manager did not hold the request on bus (Waitrequest 2/2)");

    bus.waitrequest = 0;

    @(posedge clk);

    #1
    assert (bus.read == 0)
    else $fatal("Data Manager did not stop read request when waitrequest is low; this would be interpreted as a second request");

    bus.readdatavalid = 1;
    bus.agent_to_host = 32'hAAAA5555;

    @(posedge clk);

    #1
    assert (dut.from_bus == 32'h00005555 && dut.ready == 1)
    else $fatal("Data Manager did not read halfword from bus correctly");

    reset();

    // request just a byte
    dut.address = 0;
    dut.read = 1;
    dut.size = INT_SIZE_BYTE;

    @(posedge clk);

    #1
    assert (bus.read == 1 && bus.address == 0 && bus.byteenable == 4'b0001)
    else $fatal("Data Manager did not put correct request on bus");

    bus.waitrequest = 0;
    bus.agent_to_host = 32'h11223344;
    bus.readdatavalid = 1;

    @(posedge clk);

    #1
    assert (dut.from_bus == 32'h00000044 && dut.ready == 1)
    else $fatal("Data Manager did not read byte from bus correctly");
  endtask

  task automatic test_read_halfwords_bytes_sign_extend();
    $display("Test: Data Manager can read halfwords and bytes, sign extends them");
    
    reset();

    dut.address = 0;
    dut.read = 1;
    dut.size = INT_SIZE_HALF;
    dut.zero_extend = 0;

    bus.agent_to_host = 32'h0000FFFF;
    bus.readdatavalid = 1;
    
    @(posedge clk);
    
    #1
    assert (dut.from_bus == 32'hFFFFFFFF && dut.ready == 1)
    else $fatal("Data Manager did not read halfword from bus correctly");


    reset();

    dut.address = 0;
    dut.read = 1;
    dut.size = INT_SIZE_BYTE;
    dut.zero_extend = 0;

    bus.agent_to_host = 32'h000000FF;
    bus.readdatavalid = 1;
    
    @(posedge clk);
    
    #1
    assert (dut.from_bus == 32'hFFFFFFFF && dut.ready == 1)
    else $fatal("Data Manager did not read halfword from bus correctly");

  endtask

  task automatic reset();
    $display("[%05t] Resetting", $time);
    bus.waitrequest = 1;
    bus.readdatavalid = 0;

    rst = 1;
    #1;
    rst = 0;
    @(posedge clk);
    rst = 1;
  endtask
endmodule
