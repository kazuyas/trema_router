#
# ARP processing routines
#
# Author: Kazuya Suzuki
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


def create_arp_reply message, replyaddr
  remote_nwaddr = message.arp_spa.to_array
  local_nwaddr = message.arp_tpa.to_array
  remote_dladdr = message.macsa.to_array
  local_dladdr = replyaddr.to_array
    
  data = []
  data.concat( remote_dladdr ) # dst
  data.concat( local_dladdr ) # src
  data.concat( [ 0x08, 0x06 ] )  # ether type
  # arp
  data.concat( [ 0x00, 0x01 ] ) # hardware type
  data.concat( [ 0x08, 0x00 ] ) # protocol type
  data.concat( [ 0x06 ] ) # hardware address length
  data.concat( [ 0x04 ] ) # protocol address length
  data.concat( [ 0x00, 0x02 ] ) # operation  
  data.concat( local_dladdr )
  data.concat( local_nwaddr )
  data.concat( remote_dladdr )
  data.concat( remote_nwaddr )
  while data.length < 64 do
    data.concat( [ 0x00 ] )
  end

  return data.pack( "C*" )
end


class ARPEntry
  attr_reader :dpid
  attr_reader :port
  attr_reader :mac
  attr_reader :ipaddr
  attr_writer :age_max


  def initialize dpid, port, mac, ipaddr, age_max
    @dpid = dpid
    @port = port
    @mac = mac
    @ipaddr = ipaddr
    @created = Time.now
  end

  
  def age_out?
    aged_out = Time.now - @created > @age_max
    aged_out
  end
end


class ARPTable
  DEFAULT_AGE_MAX = 300


  def initialize
    @arptable = {}
  end


  def update message
    @arptable[ message.arp_tpa ] = message.arp_tha # REVISIT
  end


  def lookup ipaddr
    if entry = @arptable[ ipaddr ]
      [ entry.mac, entry.port, entry.dpid ]
    else
      nil
    end
  end
end
  

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
