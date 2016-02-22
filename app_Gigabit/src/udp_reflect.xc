#include "udp_reflect.h"

/** Simple UDP reflection thread.
 *
 * This thread does two things:
 *
 *   - Reponds to incoming packets on port INCOMING_PORT and
 *     with a packet with the same content back to the sender.
 *   - Periodically sends out a fixed packet to a broadcast IP address.
 *
 */
void udp_handle(chanend c_xtcp,
        client interface my_interface rgb_interface,
        client interface myethernetdata_interface ethernetdata_interface[],
        unsigned n)
{
    xtcp_connection_t conn;     // A temporary variable to hold
    // connections associated with an event
    xtcp_connection_t responding_connection;    // The connection to the remote end
    // we are responding to
    int send_flag = FALSE;  // This flag is set when the thread is in the
    // middle of sending a response packet

    // The buffers for incoming data, outgoing responses and outgoing broadcast
    // messages
    char rx_buffer[RX_BUFFER_SIZE];
    char tx_buffer[RX_BUFFER_SIZE];

    int response_len;   // The length of the response the thread is sending

    int mycount = 0;

    // Maintain track of two connections. Initially they are not initialized
    // which can be represented by setting their ID to -1
    responding_connection.id = INIT_VAL;

    // Instruct server to listen and create new connections on the incoming port
    xtcp_listen(c_xtcp, INCOMING_PORT, XTCP_PROTOCOL_TCP);
    while (1)
    {
        select
        {
            // Respond to an event from the tcp server
        case xtcp_event(c_xtcp, conn):
                            switch (conn.event)
                            {
                            case XTCP_IFUP:
                            case XTCP_IFDOWN:
                                break;

                            case XTCP_NEW_CONNECTION:
                                // The tcp server is giving us a new connection.
                                // This is a new connection to the listening port
                                if (DEBUG) {
                                    printstr("New connection to listening port:");
                                    printintln(conn.local_port);}
                                if (responding_connection.id == INIT_VAL)
                                {
                                    responding_connection = conn;
                                }
                                else
                                {
                                    if (DEBUG) {
                                        printstr("Cannot handle new connection");}
                                    xtcp_close(c_xtcp, conn);
                                }
                                break;

                            case XTCP_RECV_DATA:
                                // When we get a packet in:
                                //
                                //  - fill the tx buffer
                                //  - initiate a send on that connection
                                //

                                response_len = xtcp_recv_count(c_xtcp, rx_buffer, RX_BUFFER_SIZE);
                                if (DEBUG) {
                                    printstr("Got data: ");
                                    printint(response_len);
                                    printstrln(" bytes");
                                }



                                for (int i = 0; i < response_len; i++)
                                    tx_buffer[i] = rx_buffer[i];

                                rx_buffer[response_len] = 0;
                                tx_buffer[0] = 0;
                                if (DEBUG) {
                                    printstrln(rx_buffer);
                                }
                                if (strncmp(rx_buffer, "123",3)==0) {
                                    mycount=1;
                                }
                                else
                                    mycount=0;
                                if (DEBUGR) {
                                    //strcat(tx_buffer, rx_buffer);
                                    //for (int i = 0; i < RX_BUFFER_SIZE-10; ++i) {
                                    //strcat(tx_buffer, "abcde456789123456789" );
                                }

                                //rgb_interface.rgbValues(rx_buffer,response_len);


                                //                for (int i = 0; i < n; ++i)
                                //                {
                                //                    printstr("jazza, why once? ");
                                //                    ethernetdata_interface[i].ethernetdata(rx_buffer,response_len);
                                //                    printstr("jazza, second?");
                                //                }

                                response_len = response_len + strlen(YOUSEND);
                                if (!send_flag)
                                {
                                    xtcp_init_send(c_xtcp, conn);

                                    send_flag = TRUE;
                                    //mycount=10;
                                    if (DEBUG) {
                                        printstr("Responding: ");
                                        printstrln(rx_buffer);}
                                }
                                else
                                {
                                    if (DEBUG) {
                                        printstrln("Cannot respond here since the send buffer is being used");
                                    }
                                }
                                break;

                            case XTCP_REQUEST_DATA:
                            case XTCP_RESEND_DATA:
                            case XTCP_SENT_DATA:
                                // The tcp server wants data for the reponding connection
                                if (send_flag == TRUE) {
                                    if (DEBUG)
                                    {
                                        printstr("Resending data pf length ");
                                        printintln(response_len);
                                    }
                                    //xtcp_send(c_xtcp, tx_buffer, response_len);
                                    xtcp_send(c_xtcp, tx_buffer, RX_BUFFER_SIZE);

                                } else {
                                    xtcp_complete_send(c_xtcp);
                                }
                                if (mycount <1) {
                                    send_flag = FALSE;
                                }else
                                {
                                    //mycount--;
                                }
                                break;
                                /*
                //xtcp_complete_send(c_xtcp);
                // When a reponse is sent, the connection is closed opening up
                // for another new connection on the listening port
                if (DEBUG) {
                printstrln("Sent Response");}
                //xtcp_close(c_xtcp, conn);
                //responding_connection.id = INIT_VAL;
                //send_flag = FALSE;
                break;
                                 */
                            case XTCP_TIMED_OUT:
                            case XTCP_ABORTED:
                            case XTCP_CLOSED:
                                if (DEBUG) {
                                    printstr("Closed connection:");
                                    printintln(conn.id);
                                }
                                xtcp_close(c_xtcp, conn);
                                responding_connection.id = INIT_VAL;
                                send_flag = FALSE;
                                break;

                            case XTCP_ALREADY_HANDLED:
                                break;
                            }
        break;
        }
    }
}
