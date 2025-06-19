module ProgramCounter (
    input bit clk,
    input bit rst,
    input bit increment,
    input bit load,
    input Types::int32_t step,
    input Types::int32_t in,
    output Types::int32_t out
);
  initial begin
    out = 'x;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (rst == 0) begin
      out <= 32'b0;
    end else begin
      if (load) begin
        out <= in;
      end else if (increment) begin
        out <= out + step;
      end else begin
        out <= out;
      end
    end
  end
endmodule
