import Types::triword;

interface AvalonMmRw;
  triword address;
  logic [3:0] byteenable;
  logic read;
  triword agent_to_host;
  logic write;
  triword host_to_agent;

  // Wait-State Signals
  logic waitrequest;

  // Pipeline Signals
  logic readdatavalid;

  modport Host(
      output address,
      output byteenable,
      output read,
      input agent_to_host,
      output write,
      output host_to_agent,
      input waitrequest,
      input readdatavalid
  );

  modport Agent(
      input address,
      input byteenable,
      input read,
      output agent_to_host,
      input write,
      input host_to_agent,
      output waitrequest,
      output readdatavalid
  );
endinterface  //AvalonMmRw
