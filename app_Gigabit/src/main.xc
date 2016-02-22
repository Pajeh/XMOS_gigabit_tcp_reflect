/*
 * main.xc
 *
 *
 */

#include "main.h"

// These ports are for accessing the OTP memory
otp_ports_t otp_ports = on tile[0]: OTP_PORTS_INITIALIZER;

rgmii_ports_t rgmii_ports = on tile[1]: RGMII_PORTS_INITIALIZER;

port p_smi_mdio   = on tile[1]: XS1_PORT_1C;
port p_smi_mdc    = on tile[1]: XS1_PORT_1D;
port p_eth_reset  = on tile[1]: XS1_PORT_1N;

port leds = on tile[0]: XS1_PORT_4F;

clock clk = on tile[0]: XS1_CLKBLK_1;

// IP Config - change this to suit your network.  Leave with all
// 0 values to use DHCP/AutoIP
xtcp_ipconfig_t ipconfig = {
        {169,254,158,27},//{ 0,0,0,0 }, // ip address (eg 192,168,0,2)
        {255,255,255,0},//{ 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
        {169,254,158,1}//{ 0, 0, 0, 0 } // gateway (eg 192,168,0,1)
};
//xtcp_ipconfig_t ipconfig = {
//        { 0,0,0,0 }, // ip address (eg 192,168,0,2)
//        { 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
//        { 0, 0, 0, 0 } // gateway (eg 192,168,0,1)
//};

[[combinable]]
 void ar8035_phy_driver(client interface smi_if smi,
         client interface ethernet_cfg_if eth) {
    ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
    ethernet_speed_t link_speed = LINK_1000_MBPS_FULL_DUPLEX;
    const int phy_reset_delay_ms = 1;
    const int link_poll_period_ms = 1000;
    const int phy_address = 0x4;
    timer tmr;
    int t;
    tmr :> t;
    p_eth_reset <: 0;
    delay_milliseconds(phy_reset_delay_ms);
    p_eth_reset <: 1;

    while (smi_phy_is_powered_down(smi, phy_address));
    smi_configure(smi, phy_address, LINK_1000_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);

    while (1) {
        select {
        case tmr when timerafter(t) :> t:
            ethernet_link_state_t new_state = smi_get_link_state(smi, phy_address);
            // Read AR8035 status register bits 15:14 to get the current link speed
            if (new_state == ETHERNET_LINK_UP) {
                link_speed = (ethernet_speed_t)(smi.read_reg(phy_address, 0x11) >> 14) & 3;
            }
            if (new_state != link_state) {
                link_state = new_state;
                eth.set_link_state(0, new_state, link_speed);
            }
            t += link_poll_period_ms * XS1_TIMER_KHZ;
            break;
        }
    }
}


int chartoint(char x)
{
    return (int)x-48;
}
[[combinable]]
 void led_control(server interface my_interface rgb_interface, port leds)
{
    char temp [RX_BUFFER_SIZE];
    while(1)
    {
        select
        {
        case rgb_interface.rgbValues(char message[],int length):
                        for (int i = 0; i < length; ++i)
                        {
                            temp[i] = message[i];
                        }
        temp[length] = 0;
        if(strncmp(temp,"RGB=",4)==0 && length>=8)
        {
            leds <: (chartoint(temp[7])|(chartoint(temp[6])<<1)
                    |(chartoint(temp[5])<<2)|(chartoint(temp[4])<<3));
        } else
        {
            leds <: 0;
        }
        break;
        }
    }
}


int main(void)
{
    interface my_interface rgb_interface;
    interface myethernetdata_interface ethernetdata_interface[DATAINTERFACES];
    chan c_xtcp[1];
    ethernet_cfg_if i_eth_cfg[NUM_CFG_CLIENTS];
    ethernet_rx_if i_eth_rx[NUM_ETH_CLIENTS];
    ethernet_tx_if i_eth_tx[NUM_ETH_CLIENTS];
    streaming chan c_rgmii_cfg;
    smi_if i_smi;


    par
    {
        on tile[1]: rgmii_ethernet_mac(i_eth_rx, NUM_ETH_CLIENTS, i_eth_tx, NUM_ETH_CLIENTS,
                null, null,
                c_rgmii_cfg, rgmii_ports,
                ETHERNET_DISABLE_SHAPER);
        on tile[1].core[0]: rgmii_ethernet_mac_config(i_eth_cfg, NUM_CFG_CLIENTS, c_rgmii_cfg);
        on tile[1].core[0]: ar8035_phy_driver(i_smi, i_eth_cfg[CFG_TO_PHY_DRIVER]);
        on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

        on tile[0]: xtcp(c_xtcp,
                1,
                null,
                i_eth_cfg[0],
                i_eth_rx[0],
                i_eth_tx[0],
                null,
                ETHERNET_SMI_PHY_ADDRESS,
                null,
                otp_ports,
                ipconfig);
        // The simple udp reflector thread
        on tile[0]: udp_handle(c_xtcp[0],rgb_interface, ethernetdata_interface,DATAINTERFACES);
        on tile[0]: led_control(rgb_interface, leds);



    }
    return 0;
}
