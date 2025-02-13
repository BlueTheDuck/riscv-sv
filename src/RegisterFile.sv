`default_nettype none

module RegisterFile (
    input bit clk,
    input logic [4:0] rd_sel,
    input logic [4:0] rs1_sel,
    input logic [4:0] rs2_sel,

    input  logic [31:0] rd_in,
    output logic [31:0] rs1_out,
    output logic [31:0] rs2_out,

    input bit rd_w,
    input bit rs1_en,
    input bit rs2_en
);
  word regs[32];

  initial regs[0] = 0;
  generate
    genvar i;
    for (i = 1; i < 32; i++) begin : GEN_REG_INIT
      initial regs[i] = 'x;
    end
  endgenerate

  assign rs1_out = rs1_en ? (rs1_sel != 0 ? regs[rs1_sel] : 0) : 'z;
  assign rs2_out = rs2_en ? (rs2_sel != 0 ? regs[rs2_sel] : 0) : 'z;

  always_ff @(posedge clk) begin
    if (rd_w && rd_sel != 0) begin
      regs[rd_sel] <= rd_in;
      $display("regs[%2d] <= %08x", rd_sel, rd_in);
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
