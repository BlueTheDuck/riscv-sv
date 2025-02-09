module ProgramCounter (
    input logic clk,
    input logic rst,
    input bit enabled,
    input bit load,
    input logic [31:0] step,
    input logic [31:0] in,
    output logic [31:0] curr_pc,
    output logic [31:0] next_pc
);
  logic [31:0] pc;
  initial begin
    pc = 'x;
  end
  assign curr_pc = pc;
  assign next_pc = pc + step;

  always_ff @(posedge clk or negedge rst) begin
    if (rst == 0) begin
      pc <= 32'b0;
    end else begin
      if (!enabled) begin
        pc <= pc;
      end else begin
        if (load) begin
          $display("PC <= %08x", in);
          pc <= in;
        end else begin
          pc <= next_pc;
        end
      end
    end
  end
  task automatic dump_state();
    $display(" - PC = %x; Next PC = %x", pc, pc + step);
  endtask
endmodule
