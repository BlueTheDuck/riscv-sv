// `ifndef __AVALON_SV__
// `define __AVALON_SV__

// `define avalon_host(s) \
// output word        avalon_``s``_address, \
// output bit   [3:0] avalon_``s``_byteenable, \
// input  logic       avalon_``s``_waitrequest \
// 
// `define avalon_host_write(s) \
// output bit   avalon_``s``_write, \
// output word  avalon_``s``_host_to_agent
// 
// `define avalon_host_read(s) \
// output bit  avalon_``s``_read, \
// input  word avalon_``s``_agent_to_host, \
// input  bit  avalon_``s``_readdatavalid
// 
// 
// `define avalon_host(s) \
// output word        avalon_``s``_address, \
// output bit   [3:0] avalon_``s``_byteenable, \
// input  logic       avalon_``s``_waitrequest \
// 
// `define avalon_host_write(s) \
// output bit   avalon_``s``_write, \
// output word  avalon_``s``_host_to_agent
// 
// `define avalon_host_read(s) \
// output bit  avalon_``s``_read, \
// input  word avalon_``s``_agent_to_host, \
// input  bit  avalon_``s``_readdatavalid

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
