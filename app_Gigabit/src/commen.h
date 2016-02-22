#ifndef __commen_h__
#define __commen_h__

#include <string.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>

#define DEBUG 0
#define DEBUGR 0

interface myethernetdata_interface
{
    void ethernetdata(char x[],int length);
};

#endif // __commen_h__
