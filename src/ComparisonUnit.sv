import Types::word;
import Types::comparison_op_t;

module ComparisonUnit (
    input word a,
    input word b,
    input comparison_op_t op,

    output bit result
);
  always_comb begin
    priority casez ({
      op.mode, op.un, op.neg
    })
      3'b0?0: result = a == b;
      3'b0?1: result = a != b;
      3'b100: result = $signed(a) < $signed(b);
      3'b101: result = $signed(a) >= $signed(b);
      3'b110: result = $unsigned(a) < $unsigned(b);
      3'b111: result = $unsigned(a) >= $unsigned(b);
    endcase
  end



endmodule
