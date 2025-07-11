module CpuWrapper (
    input bit clk,
    input bit rst,

    output Types::uint32_t        avalon_data_manager_address,
    output bit   [3:0] avalon_data_manager_byteenable,
    input  logic       avalon_data_manager_waitrequest,
    output bit         avalon_data_manager_write,
    output Types::uint32_t        avalon_data_manager_host_to_agent,
    output bit         avalon_data_manager_read,
    input  Types::uint32_t        avalon_data_manager_agent_to_host,
    input  bit         avalon_data_manager_readdatavalid,

    output Types::uint32_t        avalon_instruction_manager_address,
    output bit   [3:0] avalon_instruction_manager_byteenable,
    input  logic       avalon_instruction_manager_waitrequest,
    output bit         avalon_instruction_manager_read,
    input  Types::uint32_t        avalon_instruction_manager_agent_to_host,
    input  bit         avalon_instruction_manager_readdatavalid,

    output Types::uint32_t debug_current_pc,
    output Types::uint32_t debug_instruction
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


  Cpu cpu (
      .clk(clk),
      .rst(rst),
      .data_manager(data_manager.Host),
      .instruction_manager(instruction_manager.Host),
      .*
  );
endmodule
