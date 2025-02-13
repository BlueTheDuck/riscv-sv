import Types::word;

module Memory #(
    parameter int BASE = 0,
    parameter int SIZE = 1024,
    parameter string INIT_FILE = "",
    parameter string DUMP_FILE = "",
    parameter bit READ_ONLY = 1
) (
    input logic clk,
    AvalonMmRw.Agent bus
);

  byte mem[SIZE] = '{default: 0};
  word data_out;

  assign bus.agent_to_host = data_out;
  assign bus.waitrequest   = 0;

  initial begin
    for (int i = 0; i < SIZE; i++) begin
      mem[i] = 0;
    end
    if (INIT_FILE != "") begin
      int fd = $fopen(INIT_FILE, "r");
      if (fd != 0) begin
        $fread(mem, fd, 0, SIZE);
      end else begin
        $fatal("%s could not be opened", INIT_FILE);
      end
      $fclose(fd);
    end
  end

  always_ff @(posedge clk) begin
    if (bus.write && !READ_ONLY && is_valid_address(bus.address)) begin
      if (bus.byteenable[0]) mem[bus.address+0] <= bus.host_to_agent[7:0];
      if (bus.byteenable[1]) mem[bus.address+1] <= bus.host_to_agent[15:8];
      if (bus.byteenable[2]) mem[bus.address+2] <= bus.host_to_agent[23:16];
      if (bus.byteenable[3]) mem[bus.address+3] <= bus.host_to_agent[31:24];
    end
  end
  always_ff @(posedge clk) begin
    if (bus.read && is_valid_address(bus.address)) begin
      data_out[7:0] <= mem[bus.address+0];
      data_out[15:8] <= mem[bus.address+1];
      data_out[23:16] <= mem[bus.address+2];
      data_out[31:24] <= mem[bus.address+3];
      bus.readdatavalid <= 1;
      $display("read");
    end else begin
      data_out <= 'x;
      bus.readdatavalid <= 0;
    end
  end

  function logic is_valid_address(int address);
    return (BASE <= address) && (address + 3 < (BASE + SIZE));
  endfunction

  final begin
    int fd;

    if (!READ_ONLY && DUMP_FILE != "") begin
      $display("Dumping memory state to file %s", DUMP_FILE);
      fd = $fopen(DUMP_FILE, "wb");
      for (int i = 0; i < SIZE; i += 16) begin
        $fwrite(fd, "%08X: ", (i + BASE));
        for (int j = 0; j < 16; j++) begin
          $fwrite(fd, "%02X", mem[i+j]);
        end
        $fwrite(fd, "\n");
      end
      $fclose(fd);
    end
  end
endmodule
