module ProgramCounter (
    input logic clk,
    input logic rst,
    input bit enabled,
    input bit load,
    input logic [31:0] step,
    input logic [31:0] in,
    output logic [31:0] next_pc
);
  initial begin
    next_pc = 'x;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (rst == 0) begin
      next_pc <= 32'b0;
    end else begin
      if (!enabled) begin
        next_pc <= next_pc;
      end else begin
        if (load) begin
          next_pc <= in;
        end else begin
          next_pc <= next_pc + step;
        end
      end
    end
  end
endmodule
