import Types::word;

interface AvalonMmRead;
  word address;
  bit [3:0] byteenable;
  bit waitrequest;
  bit read;
  logic readdatavalid;
  word agent_to_host;

  modport Agent(
      input address,
      input byteenable,
      output waitrequest,
      input read,
      output agent_to_host,
      output readdatavalid
  );
  modport Host(
      output address,
      output byteenable,
      input waitrequest,
      output read,
      input agent_to_host,
      input readdatavalid
  );
endinterface

// `endif
