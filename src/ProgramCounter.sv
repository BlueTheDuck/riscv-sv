module ProgramCounter (
    input bit clk,
    input bit rst,
    input bit enabled,
    input bit load,
    input Types::int32_t step,
    input Types::int32_t in,
    output Types::int32_t out
);
  initial begin
    next_pc = 'x;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (rst == 0) begin
      next_pc <= 32'b0;
    end else begin
      if (load) begin
        next_pc <= in;
      end else if (enabled) begin
        next_pc <= next_pc + step;
      end else begin
        next_pc <= next_pc;
      end
    end
  end
endmodule
