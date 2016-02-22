#ifndef __udp_reflect_h__
#define __udp_reflect_h__

#include <xtcp.h>
#include <string.h>
#include <print.h>
#include "commen.h"

// Defines
#define RX_BUFFER_SIZE 1400
#define INCOMING_PORT 15533
#define INIT_VAL -1
#define YOUSEND "You sent: "
#define ETHERNET_SMI_PHY_ADDRESS (0)

enum flag_status {TRUE=1, FALSE=0};

interface my_interface
{
    void rgbValues(char x[],int length);
};

void udp_handle(chanend c_xtcp,
                client interface my_interface rgb_interface,
                client interface myethernetdata_interface ethernetdata_interface[],
                unsigned n);


#endif // __udp_reflect_h__
