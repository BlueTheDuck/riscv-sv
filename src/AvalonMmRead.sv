interface AvalonMmRead;
  tri32_t address;
  logic [3:0] byteenable;
  logic read;
  tri32_t agent_to_host;

  // Wait-State Signals
  logic waitrequest;

  // Pipeline Signals
  logic readdatavalid;

  modport Host(
      output address,
      output byteenable,
      output read,
      input agent_to_host,
      input waitrequest,
      input readdatavalid
  );
  modport Agent(
      input address,
      input byteenable,
      input read,
      output agent_to_host,
      output waitrequest,
      output readdatavalid
  );
endinterface
