module RegisterFile (
    input bit clk,
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2,

    input  logic [31:0] din,
    output logic [31:0] dout1,
    output logic [31:0] dout2,

    input bit rd_w,
    input bit rs1_en,
    input bit rs2_en
);
  bit [31:0] regs[32];

  initial regs[0] = 0;
  generate
    genvar i;
    for (i = 1; i < 32; i++) begin : GEN_REG_INIT
      initial regs[i] = 'x;
    end
  endgenerate

  assign dout1 = rs1_en ? (rs1 != 0 ? regs[rs1] : 0) : 'z;
  assign dout2 = rs2_en ? (rs2 != 0 ? regs[rs2] : 0) : 'z;

  always_ff @(posedge clk) begin
    if (rd_w && rd != 0) begin
      regs[rd] <= din;
      $display("regs[%2d] <= %08x", rd, din);
    end
  end
`ifdef DUMP_FINAL_STATE
  final begin
    $display(" - Register bank: ");
    for (int r = 0; r < 32; r += 4) begin
      $display("R%02d..R%02d: %08x, %08x, %08x, %08x", r, r + 3, regs[r], regs[r+1], regs[r+2],
               regs[r+3]);
    end
  end
`endif
endmodule
