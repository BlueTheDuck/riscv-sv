import Types::word;

module DualPortedMem #(
    parameter int SIZE = 1024,
    parameter string INIT_FILE = "",
    parameter string DUMP_FILE = ""
) (
    input bit clk,

    AvalonMmRw.Agent   rw_bus,
    AvalonMmRead.Agent ro_bus
);
  byte mem[SIZE];



  assign rw_bus.agent_to_host = {
    mem[rw_bus.address+3], mem[rw_bus.address+2], mem[rw_bus.address+1], mem[rw_bus.address+0]
  };
  assign rw_bus.waitrequest = 0;
  assign rw_bus.readdatavalid = 1;


  assign ro_bus.agent_to_host = {
    mem[ro_bus.address+3], mem[ro_bus.address+2], mem[ro_bus.address+1], mem[ro_bus.address+0]
  };
  assign ro_bus.waitrequest = 0;
  assign ro_bus.readdatavalid = 1;


  initial begin
    int fd = $fopen(INIT_FILE, "r");

    for (int i = 0; i < SIZE; i++) begin
      mem[i] = 8'h55;
    end
    if (fd != 0) begin
      $fread(mem, fd, 0);
    end else begin
      $fatal("%s could not be opened", INIT_FILE);
    end
    $fclose(fd);
  end

  always_ff @(posedge clk) begin
    if (rw_bus.write) begin
      $display("WRITE %04b, %08x", rw_bus.byteenable, rw_bus.address);
      for (int i = 0; i < 3; i++) begin
        if (rw_bus.byteenable[i]) begin
          if (rw_bus.address + i <= SIZE) begin
            mem[rw_bus.address+i] <= rw_bus.host_to_agent[i*8+:8];
            $display(" - MEM[%08X] <= %02X", (rw_bus.address + i), (rw_bus.host_to_agent[i*8+:8]));
          end
        end
      end
    end
  end

  final begin
    if (DUMP_FILE != "") begin
      int fd = $fopen(DUMP_FILE, "wb");
      if (fd != 0) begin
        for (int i = 0; i < SIZE; i += 1) begin
          $fwrite(fd, "%c", mem[i]);
        end
        $fclose(fd);
      end else begin
        $fatal("%s could not be opened", DUMP_FILE);
      end
    end
  end
endmodule
