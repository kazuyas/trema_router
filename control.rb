#
# A router implementation on Trema 
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


require "trema"
require "arp"


class Interface
  attr_reader :mac
  attr_reader :ipaddr
  attr_reader :dpid
  attr_reader :port


  def initialize dpid, port, mac, ipaddr
    @dpid = dpid
    @port = port
    @mac = Trema::Mac.new( mac )
    @ipaddr = IPAddr.new( ipaddr )
  end
end


class Control
  attr_reader :arptable

  def initialize
    @arptable = ARPTable.new

    @iftable = []
    @iftable[ 0 ] = Interface.new( 0x44, 
                                   0x1,
                                   "54:00:00:01:01:01", 
                                   "192.168.5.101"
                                   )
    @iftable[ 1 ] = Interface.new( 0x1, 
                                   0x2,
                                   "54:00:00:02:02:02", 
                                   "192.168.2.100" 
                                   )
  end
  
  
  def ours? message
    return true if message.macda.to_array == [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
#    return true if message.macda.broadcast?
  
    @iftable.each do | interface |
      next if interface.dpid != message.datapath_id
      next if interface.port != message.in_port
      next if interface.mac != message.macda
      return true
    end

    return false
  end

  
  def resolve dpid, port, ipaddr
    @iftable.each do | interface |
      next if interface.dpid != dpid
      next if interface.port != port
      next if interface.ipaddr.to_i != ipaddr.to_i
      return interface.mac
    end
    return nil
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
