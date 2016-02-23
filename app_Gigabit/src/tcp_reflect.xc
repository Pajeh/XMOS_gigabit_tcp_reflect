#include "tcp_reflect.h"

/** Simple TCP reflection thread.
 *
 * This thread does two things:
 *
 *   - Reponds to incoming packets on port INCOMING_PORT and
 *     with a packet with the same content back to the sender.
 *   - If "stream" is received, thread responds a continuous
 *     stream of data with characteres counting up until another
 *     value is received. In this case, the connection isn't closed.
 *
 */
void tcp_handle(chanend c_xtcp)
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
#ifdef DEBUG
            printstr("New connection to listening port:");
            printintln(conn.local_port);
#endif
            if (responding_connection.id == INIT_VAL)
            {
                responding_connection = conn;
            }
            else
            {
#ifdef DEBUG
                printstr("Cannot handle new connection");
#endif
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
            rx_buffer[response_len] = 0;
#ifdef DEBUG
            printstr("Got data: ");
            printint(response_len);
            printstrln(" bytes");
#endif


            if (strncmp(rx_buffer, "stream",3)==0) {
                mycount=1;
                for (int i = 0; i < RX_BUFFER_SIZE; i++)
                    tx_buffer[i] = (char ) i;
            }
            else {
                mycount=0;
                for (int i = 0; i < response_len; i++)
                    tx_buffer[i] = rx_buffer[i];
            }
            tx_buffer[0] = 0;
#ifdef DEBUG
            printstrln(rx_buffer);
#endif

            response_len = response_len + strlen(YOUSEND);
            if (!send_flag)
            {
                xtcp_init_send(c_xtcp, conn);

                send_flag = TRUE;
                //mycount=10;
#ifdef DEBUG
                printstr("Responding: ");
                printstrln(rx_buffer);}
#endif
#ifdef DEBUG
            printstrln("Cannot respond here since the send buffer is being used");
#endif
        }
        break;

        case XTCP_REQUEST_DATA:
        case XTCP_RESEND_DATA:
        case XTCP_SENT_DATA:
            // The tcp server wants data for the reponding connection
            if (send_flag == TRUE) {
#ifdef DEBUG
                printstr("Resending data pf length ");
                printintln(response_len);
#endif
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
        case XTCP_TIMED_OUT:
        case XTCP_ABORTED:
        case XTCP_CLOSED:
#ifdef DEBUG
            printstr("Closed connection:");
            printintln(conn.id);
#endif
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
