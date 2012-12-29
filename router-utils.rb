#
# A router implementation in Trema
#
# Copyright (C) 2012 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


require 'ipaddr'


class IPAddr
  def to_a
    self.to_s.split( "." ).collect do | each |
      each.to_i
    end
  end
end


module RouterUtils
  def create_ether_header macda, macsa, eth_type
    data = []
    data.concat( macda ) # dst
    data.concat( macsa ) # src
    data.concat( eth_type ) # eth_type
    data.pack( "C*" )
    return data
  end
  
  
  def create_arp_packet type, tha, sha, tpa, spa
    data = []
    data.concat( create_ether_header( tha, sha, [ 0x08, 0x06 ] ) )
    # arp
    data.concat( [ 0x00, 0x01 ] ) # hardware type
    data.concat( [ 0x08, 0x00 ] ) # protocol type
    data.concat( [ 0x06 ] ) # hardware address length
    data.concat( [ 0x04 ] ) # protocol address length
    data.concat( [ 0x00, type ] ) # operation
    data.concat( sha )
    data.concat( spa )
    data.concat( tha )
    data.concat( tpa )
    while data.length < 60 do
      data.concat( [ 0x00 ] )
    end

    return data.pack( "C*" )
  end


  def create_arp_request_from interface, addr
    spa = interface.ipaddr.to_a
    sha = interface.hwaddr.to_a

    tpa = addr.to_a
    tha = [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]

    return create_arp_packet( 0x1, tha, sha, tpa, spa )
  end


  def create_arp_reply_from message, replyaddr
    spa = message.arp_tpa.to_a
    sha = replyaddr.to_a

    tpa = message.arp_spa.to_a
    tha = message.macsa.to_a

    return create_arp_packet( 0x2, tha, sha, tpa, spa )
  end


  def create_ipv4_header message
    data = []
    data.concat( [ 0x45, 0x00 ] ) # Version, IHL, ToS

    len = [ message.ipv4_tot_len >> 8, message.ipv4_tot_len & 0xff ]
    data.concat( len ) # len
    id = [ message.ipv4_id >> 8, message.ipv4_id & 0xff ]
    data.concat( id ) # ID
    data.concat( [ 0x00, 0x00 ] ) # Flags, Frag offset
    data.concat( [ 0x40, message.ipv4_protocol ] ) # ttl, protocol
    ipv4_checksum = [ message.ipv4_checksum >> 8, message.ipv4_checksum & 0xff ]
    data.concat( ipv4_checksum ) # checksum
    data.concat( message.ipv4_daddr.to_a )
    data.concat( message.ipv4_saddr.to_a )
    data.pack( "C*" )
    return data
  end


  def create_icmpv4_reply entry, interface, message
    eth_type = [ 0x08, 0x00 ]
    data = create_ether_header( entry.hwaddr.to_a, interface.hwaddr.to_a, eth_type )

    data.concat( create_ipv4_header( message ) )

    data.concat( [ 0x00, 0x00 ] )

    val = message.icmpv4_checksum + 0x0800
    icmp_checksum = [ val >> 8, val & 0xff ]
    data.concat( icmp_checksum )

    offset = data.length
    data.concat( message.data.unpack( "C*" )[ offset .. message.data.length - 1 ] )

    return data.pack( "C*" )
  end


  def get_checksum csum, val
    sum = ~csum
    sum += val
    while sum > 0xffff
      sum = ( sum & 0xffff ) + ( sum >> 16 )
    end
    ~sum
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
