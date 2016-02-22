#ifndef __signals_h__
#define __signals_h__

#include <xs1.h>
#include <timer.h>
#include <math.h>
#include "commen.h"

#define DEFAULT_FREQ    200000
#define TIMER_FREQ  100000000

[[combinable]]
void dimm1(out port p, server interface myethernetdata_interface ethernetdata_interface);
int test(void);

#endif // __signals_h__
