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


require "arp"
require "interface"
require "routing-table"
require "packet-queue"
require "utils"
require "config"


class Router < Controller
  include Utils


  add_timer_event :age_arp_table, 5, :periodic


  def start
    @interfaces = Interfaces.new( $interface )
    @arp_table = ARPTable.new
    @routing_table = RoutingTable.new( $route )
    @unresolved_packets = PacketQueue.new
  end


  def packet_in dpid, message
    return if not ours? message

    if message.arp_request?
      handle_arp_request( dpid, message )
    elsif message.arp_reply?
      handle_arp_reply( dpid, message )
    elsif message.ipv4?
      handle_ipv4( dpid, message )
    else
      # noop.
    end
  end


  #######
  private
  #######


  def ours? message
    @interfaces.ours?( message.in_port, message.macda )
  end


  def handle_arp_request dpid, message
    port = message.in_port
    interface = @interfaces.find_by_port_and_ipaddr( port, message.arp_tpa )
    if interface
      packet = create_arp_reply( message, interface.hwaddr )
      send_packet dpid, packet, interface
    end
  end


  def handle_arp_reply dpid, message
    @arp_table.update( message.in_port, message.arp_spa, message.arp_sha )
    @unresolved_packets[ message.arp_spa.value.to_i ].each do | each |
      info "test"
    end
  end


  def handle_ipv4 dpid, message
    if should_forward?( message )
      forward dpid, message
    elsif message.icmpv4_echo_request?
      handle_icmpv4_echo_request dpid, message
    else
      # noop.
    end
  end


  def should_forward? message
    not @interfaces.find_by_ipaddr( message.ipv4_daddr )
  end


  def handle_icmpv4_echo_request dpid, message
    interface = @interfaces.find_by_port( message.in_port )
    saddr = message.ipv4_saddr.value
    arp_entry = @arp_table.lookup( saddr )
    if arp_entry
      packet = create_icmpv4_reply( arp_entry, interface, message )      
      send_packet dpid, packet, interface
    else
      packet = create_arp_request( interface, saddr )
      send_packet dpid, packet, interface
      @unresolved_packets[ saddr.to_i ] << message
    end
  end


  def forward dpid, message
    daddr = message.ipv4_daddr.value
    nexthop = @routing_table.lookup( daddr ) 
    if not nexthop
      nexthop = daddr
    end

    interface = @interfaces.find_by_prefix( nexthop )
    if not interface or interface.port == message.in_port
      return 
    end

    arp_entry = @arp_table.lookup( nexthop )
    if arp_entry
      action = interface.forward_action( arp_entry.hwaddr )
      flow_mod dpid, message, action
      packet_out dpid, message.data, action
    else
      packet = create_arp_request( interface, nexthop )
      send_packet dpid, packet, interface
      @unresolved_packets[ nexthop.to_i ] << message
    end
  end


  def flow_mod dpid, message, action
    send_flow_mod_add(
      dpid,
      :match => ExactMatch.from( message ),
      :actions => action
    )
  end


  def packet_out dpid, packet, action
    send_packet_out(
      dpid,
      :data => packet,
      :actions => action
    )
  end


  def send_packet dpid, packet, interface
    packet_out dpid, packet, ActionOutput.new( :port => interface.port )
  end


  def age_arp_table
    @arp_table.age
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
