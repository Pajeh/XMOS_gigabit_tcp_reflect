#ifndef __udp_reflect_h__
#define __udp_reflect_h__

#include <xtcp.h>
#include <string.h>
#include <print.h>

// Defines
#define RX_BUFFER_SIZE 1400
#define INCOMING_PORT 15533
#define INIT_VAL -1
#define YOUSEND "You sent: "
#define ETHERNET_SMI_PHY_ADDRESS (0)

enum flag_status {TRUE=1, FALSE=0};


void tcp_handle(chanend c_xtcp);


#endif // __udp_reflect_h__
