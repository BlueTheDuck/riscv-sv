import Types::word;

interface AvalonMmRw;
  word address;
  bit [3:0] byteenable;
  bit waitrequest;
  word host_to_agent;
  bit write;
  word agent_to_host;
  bit read;
  logic readdatavalid;
  modport Agent(
      input address,
      input byteenable,
      output waitrequest,
      input host_to_agent,
      input write,
      input read,
      output agent_to_host,
      output readdatavalid
  );
  modport Host(
      output address,
      output byteenable,
      input waitrequest,
      output host_to_agent,
      output write,
      output read,
      input agent_to_host,
      input readdatavalid
  );
endinterface  //AvalonMmRw
