#include "signals.h"

in port testinput = on tile[0]:       XS1_PORT_1P;

int chartointt(char x)
{
    return (int)x-48;
}

int stringtoint(char x[], int n)
{
    int result=0;
    for (int i = 0; i < n; ++i)
    {
        result += chartointt(x[i])*pow(10,(n-i-1));
    }
    return result;
}

[[combinable]]
void dimm1(out port p, server interface myethernetdata_interface ethernetdata_interface)
{
    char temp[300];
    char temp2[300];
    int i = 0;
    int new;
    int test = 1;
    timer tmr;
    int port_count;
    int period = TIMER_FREQ/DEFAULT_FREQ;
    int dim_value = period*0.5;
    int state = 0;
    tmr :> port_count;
    port_count += period;
    while (1) {
        select {
            case tmr when timerafter(port_count) :> void:
                if(test)
                {
                p <: state;
                state = !state;
                if (state)
                    port_count += period - dim_value;
                else
                    port_count += dim_value;
                }
            break;

            case ethernetdata_interface.ethernetdata(char message[],int length):
                for (int i = 0; i < length; ++i)
                {
                    temp[i] = message[i];
                }
                temp[length] = 0;
                if(strncmp(temp,"freq=",5)==0 && length>=6)
                {
                    for (i = 0; temp[i+5]!=0 ; ++i)
                    {
                        temp2[i]=temp[i+5];
                    }
                    temp2[i]=0;
                    new = stringtoint(temp2,i);
                    period = TIMER_FREQ/new;
                    dim_value = period*0.5;
                }
            break;

            /*case testinput when pinseq(1) :> void :
                test=1;
            break;*/
        }
    }
}

int test(void)
{
    int a = 0;
    int b = 0;
    par
    {
        a = 5+3;
        b = 6+3;
    }
    return a+b;
}
