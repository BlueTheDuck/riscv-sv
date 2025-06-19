//! Counter module that increments or loads a value based on control signals
//! Specification, in order of precedence:
//! - ¬rst => out = 0
//! - rst ∧ load => out = in
//! - rst ∧ ¬load ∧ increment => out = out + step
//! - rst ∧ ¬load ∧ ¬increment => out = out
module Counter (
    input bit clk,
    input bit rst,
    input bit increment,
    input bit load,
    input Types::int32_t step,
    input Types::int32_t in,
    output Types::int32_t out
);
  initial out = 'x;

  always_ff @(posedge clk or negedge rst) begin
    if (rst == 0) begin
      out <= 0;
    end else if (load) begin
      out <= in;
    end else if (increment) begin
      out <= out + step;
    end else begin
      out <= out;
    end
  end
endmodule
