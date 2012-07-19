#
# A router implementation on Trema
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
require "routing-table"


class Interface
  attr_reader :mac
  attr_reader :ipaddr
  attr_reader :plen
  attr_reader :port


  def initialize port, mac, ipaddr, plen
    @port = port
    @mac = Trema::Mac.new( mac )
    @ipaddr = IPAddr.new( ipaddr )
    @plen = plen
  end


  def forward_action daddr
    [
     Trema::ActionSetDlSrc.new( :dl_src => self.mac ),
     Trema::ActionSetDlDst.new( :dl_dst => daddr ),
     Trema::ActionOutput.new( self.port )
    ]
  end
end


class Interfaces
  extend Forwardable
  def_delegator :@list, :<<


  attr_reader :list


  def initialize
    @list = []
  end


  def find_by_port port
    @list.find do | each |
      each.port == port
    end
  end


  def find_by_ipaddr ipaddr
    @list.find do | each |
      each.ipaddr == ipaddr
    end
  end


  def find_by_port_and_ipaddr port, ipaddr
    interface = @list.find do | each |
      each.port == port and each.ipaddr == ipaddr
    end
  end


  def ours? port, mac
    interface = self.find_by_port( port )
    return false if interface == nil

    if mac.to_array == [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
      return true
    elsif mac == interface.mac
      return true
    else
      return false
    end
  end
end


class ControlElement
  include Trema::Logger


  attr_reader :arptable


  def initialize
    @arptable = ARPTable.new
    @rttable = RoutingTable.new
    @iftable = Interfaces.new

    new_entry = Interface.new( 39, "54:00:00:01:01:01", "192.168.11.1", 24 )
    @iftable << new_entry
    @rttable.add( new_entry.ipaddr, new_entry.plen, nil, new_entry )

    new_entry = Interface.new( 37, "54:00:00:02:02:02", "192.168.12.1", 24 )
    @iftable << new_entry
    @rttable.add( new_entry.ipaddr, new_entry.plen, nil, new_entry )

    @rttable.add( IPAddr.new( "192.168.13.0" ), 24,
                  IPAddr.new( "192.168.12.2" ), new_entry )
  end


  def ours? message
    @iftable.ours?( message.in_port, message.macda )
  end


  def is_respond? message
    if message.ipv4?
      interface = @iftable.find_by_ipaddr( message.ipv4_daddr.value )
      return true if interface != nil
    end

    if message.arp_request?
      @iftable.list.each do | each |
        next if each.port == message.in_port
        next if each.ipaddr == message.arp_tpa.value
        return true
      end
    end

    if message.arp_reply?
      return true
    end

    return false
  end


  def resolve port, ipaddr
    @iftable.find_by_port_and_ipaddr( port, ipaddr )
  end


  def lookup message
    return nil if !message.ipv4?

    route = @rttable.lookup( message.ipv4_daddr.value )
    return nil if !route

    if !route.gateway
      route.gateway = message.ipv4_daddr.value
    end
    route
  end


  def egress ipaddr
    @iftable.find_by_ipaddr( ipaddr )
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
