// `include "Types.sv"
import Types::*;
// `include "AvalonMm.sv"

module Rom #(
)(
  input logic clk,
  input logic rst,
  AvalonMmRead.Agent data_manager
);
  assign data_manager.waitrequest = 0;

  // Memory array
  word mem [4096];

  // Load initial content from file
  initial begin
    int fd = $fopen("rom.bin", "r");
    if (fd != 0) $fread(mem, fd, 0, 4096);
    else begin
      $fatal("rom.bin could not be opened");
    end
    $fclose(fd);
  end

  // Read logic
  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      data_manager.agent_to_host <= '0;
      data_manager.readdatavalid <= 0;
    end else if (data_manager.read) begin
      word address_aligned = data_manager.address & (~32'b11);
      if(address_aligned != data_manager.address) begin
        $info("Attempted to access misalgined address: %08x", data_manager.address);
      end
      data_manager.agent_to_host <= mem[address_aligned >> 2];
      data_manager.readdatavalid <= 1;
    end else begin
      data_manager.agent_to_host <= data_manager.agent_to_host;
      data_manager.readdatavalid <= 0;
    end
  end

endmodule
