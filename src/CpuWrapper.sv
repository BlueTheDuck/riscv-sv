module CpuWrapper import Types::*; (
    input bit clk,
    input bit rst,

    output uint32_t        avalon_data_manager_address,
    output bit   [3:0] avalon_data_manager_byteenable,
    input  logic       avalon_data_manager_waitrequest,
    output bit         avalon_data_manager_write,
    output uint32_t        avalon_data_manager_host_to_agent,
    output bit         avalon_data_manager_read,
    input  uint32_t        avalon_data_manager_agent_to_host,
    input  bit         avalon_data_manager_readdatavalid,

    output uint32_t        avalon_instruction_manager_address,
    output bit   [3:0] avalon_instruction_manager_byteenable,
    input  logic       avalon_instruction_manager_waitrequest,
    output bit         avalon_instruction_manager_read,
    input  uint32_t        avalon_instruction_manager_agent_to_host,
    input  bit         avalon_instruction_manager_readdatavalid,

    output uint32_t debug_current_pc,
    output uint32_t debug_instruction,
    input  bit      debug_wait,
    output bit[1023:0] debug_registers_fanout
);
  AvalonMmRw data_manager ();
  AvalonMmRead instruction_manager ();

  assign avalon_data_manager_address           = data_manager.address;
  assign avalon_data_manager_byteenable        = data_manager.byteenable;
  assign data_manager.waitrequest              = avalon_data_manager_waitrequest;
  assign avalon_data_manager_write             = data_manager.write;
  assign avalon_data_manager_host_to_agent     = data_manager.host_to_agent;
  assign avalon_data_manager_read              = data_manager.read;
  assign data_manager.agent_to_host            = avalon_data_manager_agent_to_host;
  assign data_manager.readdatavalid            = avalon_data_manager_readdatavalid;

  assign avalon_instruction_manager_address    = instruction_manager.address;
  assign avalon_instruction_manager_byteenable = instruction_manager.byteenable;
  assign instruction_manager.waitrequest       = avalon_instruction_manager_waitrequest;
  assign avalon_instruction_manager_read       = instruction_manager.read;
  assign instruction_manager.agent_to_host     = avalon_instruction_manager_agent_to_host;
  assign instruction_manager.readdatavalid     = avalon_instruction_manager_readdatavalid;

  uint32_t debug_registers[32];

  generate
    genvar i;
    for (i = 0; i < 32; i++) begin : GENERATE_DEBUG_REGISTERS_ASSIGNMENTS
      assign debug_registers_fanout[i*32 +: 32] = debug_registers[i];
    end
  endgenerate


  Cpu cpu (
      .clk(clk),
      .rst(rst),
      .data_manager(data_manager.Host),
      .instruction_manager(instruction_manager.Host),
      .*
  );
endmodule
