
#include <xs1.h>
#include <platform.h>
#include <xtcp.h>
#include "udp_reflect.h"
#include "signals.h"
#include "commen.h"

// Defines
#define ETHERNET_SMI_PHY_ADDRESS (0)
#define DATAINTERFACES  5


// Ports
out port d1[11] = on tile[0]: {XS1_PORT_1E,
                               XS1_PORT_1F,
                               XS1_PORT_1G,
                               XS1_PORT_1H,
                               XS1_PORT_1I,
                               XS1_PORT_1J,
                               XS1_PORT_1K,
                               XS1_PORT_1L,
                               XS1_PORT_1M,
                               XS1_PORT_1N,
                               XS1_PORT_1O};

out port d4[2] = on tile[0]:  {XS1_PORT_4C,
                               XS1_PORT_4D};



// An enum to manage the array of connections from the ethernet component
// to its clients.
enum eth_clients {
  ETH_TO_ICMP,
  NUM_ETH_CLIENTS
};

enum cfg_clients {
  CFG_TO_ICMP,
  CFG_TO_PHY_DRIVER,
  NUM_CFG_CLIENTS
};


