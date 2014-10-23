/*

Copyright (C) 2013 by Brandon Casey & Anthony Lucillo

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/


// Required for XS file
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// Required for module
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/sctp.h>
#include <arpa/inet.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

struct SockOptInfo
{
  void* data;
  int sockOption;
};

int GetHashValue( HV* hash, char* key )
{
  SV* key_sv = newSVpv( key, 0 );
  if( !hv_exists_ent(hash, key_sv, 0) )
  {
    return -1;
  }

  HE* he_val = hv_fetch_ent( hash, key_sv, 0, 0 );
  SV* val = HeVAL(he_val);

  return (int)SvIV(val);
}

struct SockOptInfo BuildStruct( HV* hash, char* struct_type )
{
  struct SockOptInfo t_sockOptData = {0};
  int val;

  if( 0 == strcmp("SCTP_EVENTS", struct_type) )
  {
    struct sctp_event_subscribe t_opt = {0};

    val = GetHashValue(hash, "sctp_association_event");
    if( 0 < val ) t_opt.sctp_association_event = val;

    val = GetHashValue(hash, "sctp_address_event");
    if( 0 < val ) t_opt.sctp_address_event = val;

    val = GetHashValue(hash, "sctp_send_failure_event");
    if( 0 < val ) t_opt.sctp_send_failure_event = val;

    val = GetHashValue(hash, "sctp_peer_error_event");
    if( 0 < val ) t_opt.sctp_peer_error_event = val;

    val = GetHashValue(hash, "sctp_shutdown_event");
    if( 0 < val ) t_opt.sctp_shutdown_event = val;

    val = GetHashValue(hash, "sctp_partial_delivery_event");
    if( 0 < val ) t_opt.sctp_partial_delivery_event = val;

    val = GetHashValue(hash, "sctp_adaption_layer_event"); // <<< this variable name appears to be different in newer versions of the spec
    if( 0 < val ) t_opt.sctp_adaption_layer_event = val;

    /*
    ****NOTE: The version of SCTP installed on our machine does have these struct variables defined

    val = GetHashValue(hash, "sctp_authentication_event");
    if( 0 < val ) t_opt.sctp_authentication_event = val;

    val = GetHashValue(hash, "sctp_sender_dry_event");
    if( 0 < val ) t_opt.sctp_sender_dry_event = val;
    */

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_EVENTS;
  }
  else if( 0 == strcmp("SCTP_RTOINFO", struct_type) )
  {
    struct sctp_rtoinfo t_opt = {0};

    val = GetHashValue(hash, "srto_initial");
    if( 0 < val ) t_opt.srto_initial = val;

    val = GetHashValue(hash, "srto_max");
    if( 0 < val ) t_opt.srto_max = val;

    val = GetHashValue(hash, "srto_min");
    if( 0 < val ) t_opt.srto_min = val;

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_RTOINFO;
  }
  else if( 0 == strcmp("SCTP_ASSOCINFO", struct_type) )
  {
    struct sctp_assocparams t_opt = {0};

    val = GetHashValue(hash, "sasoc_assoc_id");
    if( 0 < val ) t_opt.sasoc_assoc_id = val;

    val = GetHashValue(hash, "sasoc_asocmaxrxt");
    if( 0 < val ) t_opt.sasoc_asocmaxrxt = val;

    val = GetHashValue(hash, "sasoc_number_peer_destinations");
    if( 0 < val ) t_opt.sasoc_number_peer_destinations = val;

    val = GetHashValue(hash, "sasoc_peer_rwnd");
    if( 0 < val ) t_opt.sasoc_peer_rwnd = val;

    val = GetHashValue(hash, "sasoc_local_rwnd");
    if( 0 < val ) t_opt.sasoc_local_rwnd = val;

    val = GetHashValue(hash, "sasoc_cookie_life");
    if( 0 < val ) t_opt.sasoc_cookie_life  = val;

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_ASSOCINFO;
  }
  else if( 0 == strcmp("SCTP_INITMSG", struct_type) )
  {
    struct sctp_initmsg t_opt = {0};

    val = GetHashValue(hash, "sinit_num_ostreams");
    if( 0 < val ) t_opt.sinit_num_ostreams = val;

    val = GetHashValue(hash, "sinit_max_instreams");
    if( 0 < val ) t_opt.sinit_max_instreams = val;

    val = GetHashValue(hash, "sinit_max_attempts");
    if( 0 < val ) t_opt.sinit_max_attempts = val;

    val = GetHashValue(hash, "sinit_max_init_timeo");
    if( 0 < val ) t_opt.sinit_max_init_timeo = val;

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_INITMSG;
  }
  else if( 0 == strcmp("SCTP_ADAPTION_LAYER", struct_type) )
  {
    struct sctp_setadaption t_opt = {0};

    val = GetHashValue(hash, "ssb_adaption_ind");
    if( 0 < val ) t_opt.ssb_adaption_ind = val;

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_ADAPTION_LAYER;
  }
  else if( 0 == strcmp("SCTP_DELAYED_ACK_TIME", struct_type) )
  {
    struct sctp_assoc_value t_opt = {0};

    val = GetHashValue(hash, "assoc_id");
    if( 0 < val ) t_opt.assoc_id = val;

    val = GetHashValue(hash, "assoc_value");
    if( 0 < val ) t_opt.assoc_value = val;

    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_DELAYED_ACK_TIME;
  }
  /*else if( 0 == strcmp("SCTP_STATUS", struct_type) )
  {
    struct xxxx t_opt = {0};

    val = GetHashValue(hash, "sstat_assoc_id");
    if( 0 < val ) t_opt.sstat_assoc_id = val;

    val = GetHashValue(hash, "sstat_state");
    if( 0 < val ) t_opt.sstat_state = val;

    val = GetHashValue(hash, "sstat_rwnd");
    if( 0 < val ) t_opt.sstat_rwnd = val;

    val = GetHashValue(hash, "sstat_unackdata");
    if( 0 < val ) t_opt.sstat_unackdata = val;

    val = GetHashValue(hash, "sstat_penddata");
    if( 0 < val ) t_opt.sstat_penddata = val;

    val = GetHashValue(hash, "sstat_instrms");
    if( 0 < val ) t_opt.sstat_instrms = val;

    val = GetHashValue(hash, "sstat_outstrms");
    if( 0 < val ) t_opt.sstat_outstrms = val;

    val = GetHashValue(hash, "sstat_fragmentation_point");
    if( 0 < val ) t_opt.sstat_fragmentation_point = val;


sstat_primary << struct sctp_paddrinfo
struct sctp_paddrinfo {
  sctp_assoc_t    spinfo_assoc_id;
  struct sockaddr_storage spinfo_address;
  __s32     spinfo_state;
  __u32     spinfo_cwnd;
  __u32     spinfo_srtt;
  __u32     spinfo_rto;
  __u32     spinfo_mtu;
} __attribute__((packed, aligned(4)));

struct sockaddr {
  sa_family_t sa_family;  // address family, AF_xxx
  char    sa_data[14];  // 14 bytes of protocol address
};

typedef unsigned short  sa_family_t;

struct in_addr {
  __u32 s_addr;
};


    t_sockOptData.data = &t_opt;
    t_sockOptData.sockOption = SCTP_STATUS;
  }*/

  /*
  -------- SCTP_RTOINFO
  -------- SCTP_ASSOCINFO
  -------- SCTP_INITMS
  ?????? SCTP_AUTOCLOSE <<<<< no structure in file...
  SCTP_SET_PEER_PRIMARY_ADDR <<<<< ( need a way to have a third level optional hash )
  SCTP_PRIMARY_ADDR <<<<< ( need a way to have a third level optional hash )
  -------- SCTP_ADAPTION_LAYER
  ?????? SCTP_DISABLE_FRAGMENTS <<<<< no structure in file...
  SCTP_PEER_ADDR_PARAMS <<<<< ( enumeration )
  ?????? SCTP_DEFAULT_SEND_PARAM <<<<< no structure in file...
  ------ SCTP_EVENTS
  ?????? SCTP_I_WANT_MAPPED_V4_ADDR <<<<< no structure in file...
  ?????? SCTP_MAXSEG <<<<< no structure in file...
  SCTP_AUTH_CHUNK <<<<<< ( not in the file.... )
  SCTP_AUTH_KEY <<<<<< ( not in the file.... )
  SCTP_PEER_AUTH_CHUNKS <<<<<< ( not in the file.... )
  SCTP_LOCAL_AUTH_CHUNKS <<<<<< ( not in the file.... )
  SCTP_HMAC_IDENT <<<<<< ( not in the file.... )
  SCTP_AUTH_SETKEY_ACTIVE <<<<<< ( not in the file.... )
  ------ SCTP_DELAYED_ACK_TIME
  SCTP_STATUS <<<<< ( need a way to have a fourth level optional hash )
  ?????? SCTP_GET_PEER_ADDR_INFO <<<<< no structure in file...
  */

  return t_sockOptData;
}

MODULE = Net::SCTP   PACKAGE = Net::SCTP

##-----------------------------------------------------------------------------
#/Start Subroutine  : _socket
#
# Purpose           : Create a socket
# Params            : b_inet6, b_many
# Returns           : 0 on success -1 on failure
# b_inet6           : determines what version of ip to use for the
#                     for the socket.
# b_many            : determines whether to socket
#                     is using the new style one to many (if true) socket
#                     or the old style (if false)

int
_socket(b_inet6, b_many)
    bool b_inet6
    bool b_many

  CODE:
    // AF_INET for IPv4, b_inet6  = false
    // AF_INET6 for IPv6, b_inet6 = true
    // SOCK_SEQPACKET for one to many, b_many = true
    // SOCK_STREAM for one to one, b_many     = false


    // Set our return value equal to the function
    // call so we can return that to perl
    RETVAL = socket(((b_inet6) ? AF_INET6 : AF_INET),
                  ((b_many) ? SOCK_SEQPACKET : SOCK_STREAM) , IPPROTO_SCTP);

    // RETVAL was a failure, print out the error to the user because
    // Perl cannot do it.
    if( RETVAL < 0 )
    {
      printf("After socket errno: %d\n", errno);
      perror("Description: ");
    }

  OUTPUT:
    RETVAL

#\End Subroutine    : _socket
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _bind
#
# Purpose           : bind an address with a socket
# Returns           : 0 on success -1 on failure
# i_sd              : The socket descriptor to bind to.
# i_port            : The port to bind to.
# sz_ip             : The ip to bind to
# b_inet6           : Whether the connection is v6 or v4

int
_bind( i_sd, i_port, sz_ip, b_inet6)
    int i_sd
    int i_port
    char* sz_ip
    bool b_inet6

  PREINIT:
    // The structure that the addresses need to be inside of when passed to the
    // actual sctp function.
    struct sockaddr_in t_addr;

  CODE:
    // Zero out the memory of the structure
    bzero( (void *)&t_addr, sizeof(struct sockaddr_in) );

    // AF_INET for IPv4, b_inet is false
    // AF_INET6 for IPv6, b_inet is true

    // Build the structure to pass into the sctp function
    t_addr.sin_family = ( (b_inet6) ? AF_INET6 : AF_INET );
    t_addr.sin_port = i_port;
    t_addr.sin_addr.s_addr = inet_addr(sz_ip);

    // Set our return value equal to the function
    // call so we can return that to perl
    RETVAL = bind(i_sd, (struct sockaddr *)&t_addr, sizeof(struct sockaddr_in));

    // RETVAL was a failure, print out the error to the user because
    // Perl cannot do it.
    if( RETVAL < 0 )
    {
      printf("After bind errno: %d\n", errno);
      perror("Description: ");
    }

  OUTPUT:
    RETVAL

#\End Subroutine    : _bind
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _setsockopt
#
# Purpose           : Set socket options given a socket and the options to set
# Returns           :
# i_sd              : The socket descriptor to set options on
# hash              : The hash of options that has a hash of options inside.
# Note              : Example
#                     my %SCTP_EVENTS =  (sctp_association_event => 1,);
#                     my %hash_to_try =  (SCTP_EVENTS => \%SCTP_EVENTS,);
#                     Also note that not all options are currently supported.

void
_setsockopt( i_sd, hash )
    int i_sd
    HV* hash
  CODE:

    int val_length;
    int numHashes = hv_iterinit(hash);
    int a = 0;
    for( a = 0; a < numHashes; a++ ) // outer hash
    {
      HE* outer_iter = hv_iternext(hash);
      if( !outer_iter ) break;

      SV* outer_key = hv_iterkeysv( outer_iter );
      char* struct_key = SvPV(outer_key, val_length);
      HV* outer_entry = (HV*)hv_iterval(hash, outer_iter );
      HV* inner_hash = (HV*)SvRV(outer_entry);

      struct SockOptInfo sockopt_struct = BuildStruct( inner_hash, struct_key );
      int res = setsockopt( i_sd, IPPROTO_SCTP, sockopt_struct.sockOption, sockopt_struct.data, sizeof(struct sctp_event_subscribe) );

      if( res < 0 )
      {
        printf("After setsockopt errno: %d\nSocket Option: %s\n", errno, struct_key);
        perror("Description: ");
      }
    }

#\End Subroutine    : _setsockopt
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _getsockopt
#
# Purpose           : Get socket options that are set on a socket
# Returns           : The hash referencese that is passed in will be filled
# i_sd              : The socket descriptor to get options from
# hash              : The hash of options that has a hash of options inside.
# Note              : Currently in a non-working state.


void
_getsockopt( i_sd )
    int i_sd
    //HV* hash
  PREINIT:
    //HV* outer_hash = newHV();
    //HV* inner_hash = newHV();
    struct SockOptInfo sockopt_struct;
    struct sctp_event_subscribe t_event;
    struct sctp_status status;
  CODE:
    int size = sizeof(t_event);
    //int outcome = getsockopt(i_sd, SOL_SCTP, SCTP_STATUS, &status, (socklen_t *)&i))
    int outcome = getsockopt(i_sd, IPPROTO_SCTP, SCTP_EVENTS, &t_event, (socklen_t *)&size);
    printf("HERE\n");
    printf("sockopt_struct.data: %d\n", t_event.sctp_association_event);

    if( outcome < 0 )
    {
      printf("After getsockopt errno: %d\n", errno);
      perror("Description: ");
    }

#\End Subroutine    : _getsockopt
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _listen
#
# Purpose           : listen on a socket
# Returns           : 0 on success -1 on failure
# i_sd              : The socket descriptor to bind to.
# i_listen          : 1 to listen or 0 to not listen

int
_listen( i_sd, i_listen)
    int i_sd
    int i_listen
  CODE:
    RETVAL = listen( i_sd, i_listen );

    if( RETVAL < 0 )
    {
      printf("After listen errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _listen
##-----------------------------------------------------------------------------



##-----------------------------------------------------------------------------
#/Start Subroutine  : _close
#
# Purpose           : close the connection on a socket
# i_sd              : The socket descriptor to bind to.

int
_close(i_sd)
    int i_sd
  CODE:
    close(i_sd);

#\End Subroutine    : _close
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _shutdown
#
# Purpose           : close the connection on a socket
# i_sd              : The socket descriptor to bind to.
# i_how             : 0 = Disables further receive operations
#                     1 = Disables further sends, and starts SCTP shutdown
#                     2 = Disables further send and receive operations
#                         and initiates the SCTP shutdown sequence.

int
_shutdown( i_sd, i_how )
    int i_sd
    char* i_how
  CODE:
    RETVAL = shutdown( i_sd, i_how );

#\End Subroutine    : _shutdown
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _getpeername
#
# Purpose           : Get the socket of a peer on a one to one style socket
# i_sd              : The socket descriptor the peer is bound to
# sz_ip             : The ip address that will be filled out on return
# i_len             : The size of the ip address filled on return
# Note              : Does not work on one to many style sockets
#                     Currently in a non-working state

int
_getpeername(i_sd, sz_ip, i_len)
    int i_sd
    char* sz_ip
    int i_len
  PREINIT:
    struct sockaddr t_addr = {0};
  CODE:
    RETVAL = getpeername( i_sd, &t_addr,(void*) sizeof(struct sockaddr) );

    if( RETVAL < 0 )
    {
      printf("After getpeername errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _getpeername
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_sendmsg
#
# Purpose           : send a message to someone over sctp
# i_sd              : The socket descriptor of the sender
# sz_msg            : The message to be sent
# i_port            : The port to send the message over
# sz_ip             : The ip address to send the message to
# b_inet6           : ipv6 is true, ipv4 is false
# i_ppid            : NYI
# i_flags           : NYI
# i_stream          : NYI
# i_pr_value        : NYI
# i_context         : NYI

int
_sctp_sendmsg( i_sd, sz_msg, i_port, sz_ip, b_inet6, i_ppid = 0, i_flags = 0, i_stream = 0, i_pr_value = 0, i_pr_value = 0, i_context = 0 )
    int i_sd
    char* sz_msg
    int i_port
    char* sz_ip
    bool b_inet6
    int i_ppid
    int i_flags
    int i_stream
    int i_pr_value
    int i_context
  PREINIT:
    struct sockaddr_in t_addr = {0};
  CODE:
    // AF_INET for IPv4
    // AF_INET6 for IPv6
    t_addr.sin_family = ( (b_inet6) ? AF_INET6 : AF_INET );
    t_addr.sin_port = i_port;
    t_addr.sin_addr.s_addr = inet_addr( sz_ip );


    RETVAL = sctp_sendmsg( i_sd, (const void *)sz_msg, strlen(sz_msg), (struct sockaddr *)&t_addr, sizeof(struct sockaddr_in), htonl(i_ppid), i_flags, i_stream /*stream 0*/, i_pr_value, i_context);

    if( RETVAL < 0 )
    {
      printf("After sctp_sendmsg errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_sendmsg
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_recvmsg
#
# Purpose           : send a message to someone over sctp
# i_sd              : The socket descriptor to listen on
# sz_msg            : The message to be received
# i_port            : The port to listen on
# sz_addr           : The size of the message
# i_flags           : NYI

int
_sctp_recvmsg( i_sd, sz_msg, i_buffer_size, i_port, sz_addr, i_flags = 0 )
  int i_sd
  char* sz_msg
  int i_buffer_size
  int i_port
  char* sz_addr
  int i_flags
PREINIT:
  struct sockaddr_in t_addr = {0};
  struct sctp_sndrcvinfo t_sinfo = {0};
  int new_len;
  socklen_t i_addr_len = (socklen_t)sizeof(struct sockaddr_in);
  int i_in_len = i_buffer_size + 1;
  char sz_in_msg[i_in_len];
  int len = 0;
CODE:
  len = sctp_recvmsg( i_sd, (void*)sz_in_msg, i_buffer_size, (struct sockaddr *)&t_addr, &i_addr_len, &t_sinfo, &i_flags );
  if( -1 == len )
  {
    printf("After sctp_recvmsg errno: %d\n", errno);
    perror("Description: ");
  }

  sz_in_msg[len] = '\0';
  new_len = len + 1;
  char message_buffer[new_len];
  memcpy( message_buffer, sz_in_msg, new_len );
  sz_msg = message_buffer;

  i_port = t_addr.sin_port;
  sz_addr = inet_ntoa(t_addr.sin_addr);

  RETVAL = len;
OUTPUT:
  sz_msg
  i_port
  sz_addr
  RETVAL

#\End Subroutine    : _sctp_recvmsg
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _connect
#
# Purpose           : send a message to someone over sctp
# i_sd              : The socket descriptor of the client who is connecting
# i_port            : The port to connect to
# sz_ip             : The ip address to connect to
# b_inet6           : The version of ip we are using, true for v6 false for v4

int
_connect( i_sd, i_port, sz_ip, b_inet6 )
    int i_sd
    int i_port
    char* sz_ip
    bool b_inet6
  PREINIT:
    struct sockaddr_in servaddr;
  CODE:
    bzero( (void *)&servaddr, sizeof(struct sockaddr_in) );
      // AF_INET for IPv4
      // AF_INET6 for IPv6
    servaddr.sin_family = ( (b_inet6) ? AF_INET6 : AF_INET );
    servaddr.sin_port = i_port;
    servaddr.sin_addr.s_addr = inet_addr( sz_ip );
    RETVAL=connect( i_sd, (struct sockaddr *)&servaddr, sizeof(struct sockaddr_in) );
    if( RETVAL )
    {
      printf("After connect errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _connect
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _accept
#
# Purpose           : accept a connection in one to one style
# Returns           : Returns the socket desriptor of the person
#                     that is connecting
# i_sd              : The socket descriptor of the server

int
_accept( i_sd )
    int i_sd
  CODE:
    RETVAL = accept( i_sd, (struct sockaddr *)NULL, (socklen_t *)NULL );

    if( RETVAL < 0 )
    {
      printf("After accept errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _accept
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_bindx
#
# Purpose           : Bind the server ti multiple connections
# Returns           : Success(0) or failure(-1)
# i_sd              : The socket descriptor of the server
# i_port            : The port of the server
# av_sz_ip          : The array of ips to bind to
# av_b_inet6        : The array of ip versions created for the user in perl
# i_flags           : 1 is add these addresses 2 is remove them

int
_sctp_bindx(i_sd, i_port, av_sz_ip, av_b_inet6, i_flags)
    int i_sd
    int i_port
    SV* av_sz_ip
    SV* av_b_inet6
    int i_flags
  PREINIT:
    int i = 0;
    int i_addr_cnt;
  CODE:
    AV* array_length = (AV *) SvRV (av_b_inet6);
    i_addr_cnt = av_len(array_length);
    struct sockaddr_in t_addrs[i_addr_cnt];
    while(i <= i_addr_cnt)
    {

      SV** item2 = av_fetch(array_length, i, 0);
      bool temp_int = (bool)SvIV(*item2);


      AV* array = (AV *) SvRV (av_sz_ip);
      SV** item = av_fetch(array, i, 0);
      char* temp_str = SvPVX(*item);

      t_addrs[i].sin_family = ((temp_int) ? AF_INET6 : AF_INET );
      t_addrs[i].sin_port = i_port;
      t_addrs[i].sin_addr.s_addr = inet_addr(temp_str);
      ++i;
    }
    RETVAL = sctp_bindx( i_sd, (struct sockaddr *)&t_addrs, i_addr_cnt + 1, i_flags );

    if( RETVAL < 0 )
    {
      printf("After bindx errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_bindx
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_connectx
#
# Purpose           : Attempts to connect to a server using multiple addresses
# Returns           : Success(0) or failure(-1)
# i_sd              : The socket descriptor of the client
# i_port            : The port of the server
# av_sz_ip          : The array of ips to connect to
# av_b_inet6        : The array of ip versions created for the user in perl
# i_id              : The association id to give the association that is
#                     being set up

int
_sctp_connectx(i_sd, i_port, av_sz_ip, av_b_inet6, i_id = 0)
    int i_sd
    int i_port
    SV* av_sz_ip
    SV* av_b_inet6
    int i_id;
  PREINIT:
    int i = 0;
    int i_addr_cnt;
  CODE:
    AV* array_length = (AV *) SvRV (av_b_inet6);
    i_addr_cnt = av_len(array_length);
    struct sockaddr_in t_addrs[i_addr_cnt];

    while(i <= i_addr_cnt)
    {

      SV** item2 = av_fetch(array_length, i, 0);
      int temp_int = (int)SvIV(*item2);


      AV* array = (AV *) SvRV (av_sz_ip);
      SV** item = av_fetch(array, i, 0);
      char* temp_str = SvPVX(*item);

      t_addrs[i].sin_family = ((temp_int) ? AF_INET6 : AF_INET );
      t_addrs[i].sin_port = i_port;
      t_addrs[i].sin_addr.s_addr = inet_addr(temp_str);
      ++i;
    }
    RETVAL = sctp_connectx( i_sd, (struct sockaddr *)&t_addrs, i_addr_cnt + 1);

    if( RETVAL < 0 )
    {
      printf("After connectx errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_connectx
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_peeloff
#
# Purpose           : Take an association and separate it to another
# Returns           : Returns the association id of the new association
# i_sd              : The socket descriptor of the server
# i_assoc_id        : The association id to change to another one
# Note              : Currently untested

int
_sctp_peeloff(i_sd, i_assoc_id)
    int i_sd
    int i_assoc_id
  CODE:
    RETVAL = sctp_peeloff(i_sd, i_assoc_id);

    if( RETVAL < 0 )
    {
      printf("After peeloff errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_peeloff
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_getpaddrs
#
# Purpose           : Returns all peer addresses in an association
# Returns           : Fills out the arrays passed with peer addresses
# i_sd              : The socket descriptor of the client
# i_port            : The port to be filled
# av_sz_ip          : The array of ips to to be filled
# av_b_inet6        : The array of ip versions to be filled
# i_id              : The association id to get the addresses from
#                   : Automatically calls sctp_freepaddrs

int
_sctp_getpaddrs(i_sd, i_id, av_sz_ip,av_i_port, av_b_inet6)
    int i_sd
    int i_id
    SV* av_sz_ip
    SV* av_i_port
    SV* av_b_inet6
  PREINIT:
    struct sockaddr_in * t_addrs;
    int i = 0;
    AV* array_ip = (AV *) SvRV (av_sz_ip);
    AV* array_port = (AV *) SvRV (av_i_port);
    AV* array_inet6 = (AV *) SvRV (av_b_inet6);
  CODE:
    RETVAL = sctp_getladdrs(i_sd, i_id, (struct sockaddr **)&t_addrs);

    while(i < RETVAL)
    {
      char* temp_c_ip = (char*)inet_ntoa(*(struct in_addr *)&t_addrs[i].sin_addr.s_addr);
      SV* temp_ip = newSVpvn(temp_c_ip, strlen(temp_c_ip));
      av_push(array_ip, temp_ip);

      SV* temp_port = newSViv(t_addrs[i].sin_port);
      av_push(array_port, temp_port);

      SV* temp_family = newSViv(t_addrs[i].sin_family);
      av_push(array_inet6, temp_family);
      ++i;
    }
    sctp_freepaddrs(t_addrs);
    if( RETVAL < 0 )
    {
      printf("After getpaddrs errno: %d\n", errno);
      perror("Description: ");
    }

  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_getpaddrs
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : _sctp_getladdrs
#
# Purpose           : Returns all local addresses in an association
# Returns           : Fills out the arrays passed with local addresses
# i_sd              : The socket descriptor of the client
# i_port            : The port to be filled
# av_sz_ip          : The array of ips to to be filled
# av_b_inet6        : The array of ip versions to be filled
# i_id              : The association id to get the addresses from
#                     Automatically calls sctp_freeladdrs

int
_sctp_getladdrs(i_sd, i_id, av_sz_ip, av_i_port, av_b_inet6)
    int i_sd
    int i_id
    SV* av_sz_ip
    SV* av_i_port
    SV* av_b_inet6
  PREINIT:
    struct sockaddr_in * t_addrs;
    int i = 0;
    AV* array_ip = (AV *) SvRV (av_sz_ip);
    AV* array_port = (AV *) SvRV (av_i_port);
    AV* array_inet6 = (AV *) SvRV (av_b_inet6);
  CODE:
    RETVAL = sctp_getladdrs(i_sd, i_id, (struct sockaddr **)&t_addrs);

    while(i < RETVAL)
    {
      char* temp_c_ip = (char*)inet_ntoa(*(struct in_addr *)&t_addrs[i].sin_addr.s_addr);
      SV* temp_ip = newSVpvn(temp_c_ip, strlen(temp_c_ip));
      av_push(array_ip, temp_ip);

      SV* temp_port = newSViv(t_addrs[i].sin_port);
      av_push(array_port, temp_port);

      SV* temp_family = newSViv(t_addrs[i].sin_family);
      av_push(array_inet6, temp_family);
      ++i;
    }
    sctp_freeladdrs(t_addrs);

    if( RETVAL < 0 )
    {
      printf("After getladdrs errno: %d\n", errno);
      perror("Description: ");
    }
  OUTPUT:
    RETVAL

#\End Subroutine    : _sctp_getladdrs
##-----------------------------------------------------------------------------


## Not Supported Stuff:
#
# SCTP_SENDX
#
# i_ppid -- message_id so chunks can be put together (OPTIONAL)
# i_stream -- 0 = out | 1 = input | 2 = error
#int
#_sctp_sendx( i_sd, sz_msg, i_port, av_sz_ip, av_b_inet6, i_flags = 0)
#    int i_sd
#    char* sz_msg
#    int i_port
#    SV* av_sz_ip
#    SV* av_b_inet6
#    int i_flags
#  PREINIT:
#    int i_addr_cnt = 0;
#    int i = 0;
#  CODE:
#    AV* array_length = (AV *) SvRV (av_b_inet6);
#    i_addr_cnt = av_len(array_length);
#    struct sockaddr_in t_addrs[i_addr_cnt];
#
#
#    while(i <= i_addr_cnt)
#    {
#      SV** item2 = av_fetch(array_length, i, 0);
#      bool temp_int = (bool)SvIV(*item2);
#
#
#      AV* array = (AV *) SvRV (av_sz_ip);
#      SV** item = av_fetch(array, i, 0);
#      char* temp_str = SvPVX(*item);
#
#      t_addrs[i].sin_family = ((temp_int) ? AF_INET6 : AF_INET );
#      printf("Family:%d\n", temp_int);
#      t_addrs[i].sin_port = i_port;
#      t_addrs[i].sin_addr.s_addr = inet_addr(temp_str);
#      printf("IP:%s\n", temp_str);
#      ++i;
#    }
#
#
#    RETVAL = sctp_sendx( i_sd, (const void *)sz_msg, strlen(sz_msg), (struct sockaddr *)&t_addrs, (struct sctp_sndrcvinfo *) NULL, i_flags);
#
#    //if( RETVAL < 0 )
#    {
#      printf("After sctp_sendx errno: %d\n", errno);
#      perror("Description: ");
#    }
#  OUTPUT:
#    RETVAL
#
#
#
# SENDV
# ssize_t sctp_sendv(int sd, const struct iovec *iov, int iovcnt, struct sockaddr *addrs, int addrcnt, void *info, socklen_t infolen, unsigned int infotype, int flags);
# Free all the stuff that we allocated in GETLADDRS
#ssize_t
#_sctp_sendv(i_sd, t_iov, i_iov_len, sz_addrs, i_addrcnt, info, i_info_len, i_infotype, i_flags)
#    int i_sd
#    AV* t_iov
#    int i_iov_len
#    char* sz_addrs
#    int i_addrcnt
#    void* info
#    int i_info_len
#    unsigned int i_infotype
#    int i_flags
#
#  CODE:
#
#
#    RETVAL = sctp_sendv(i_sd, (struct iovec *) t_iov, i_iov_len, sz_addrs, i_addrcnt, info,i_info_len, i_infotype, i_flags);
#
#    // if( RETVAL < 0 )
#    {
#      printf("After sendv errno: %d\n", errno);
#      perror("Description: ");
#    }
#
#  OUTPUT:
#
#
# RECVV
# ssize_t sctp_recvv(int sd, const struct iovec *iov, int iovlen, struct sockaddr *from, socklen_t *fromlen, void *info, socklen_t *infolen, unsigned int *infotype, int *flags);
# Free all the stuff that we allocated in GETLADDRS
#ssize_t
#_sctp_recvv(i_sd, t_iov, i_iov_len, sz_from, i_from_len, info, i_info_len, i_infotype, i_flags)
#    int i_sd
#    AV* t_iov
#    int i_iov_len
#    char* sz_from
#    int i_from_len
#    void* info
#    int i_info_len
#    unsigned int i_infotype
#    int i_flags
#  CODE:
#
#
#    RETVAL = sctp_recvv(i_sd, (struct iovec *) t_iov, i_iov_len, sz_from, i_from_len, info, i_info_len, i_infotype, i_flags);
#
#    //if( RETVAL < 0 )
#    {
#      printf("After recvv errno: %d\n", errno);
#      perror("Description: ");
#    }
#
#  OUTPUT:

