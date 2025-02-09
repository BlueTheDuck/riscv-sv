module Mux #(
    parameter int W = 32,
    parameter int INS = 2
) (
    input logic [$clog2(INS)-1:0] sel,
    input logic [W-1:0] in[INS],
    output logic [W-1:0] out
);

  always_comb begin
    out = in[sel];
  end

endmodule
