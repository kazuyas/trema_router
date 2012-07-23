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
      send_packet dpid, port, create_arp_reply( message, interface.hwaddr )
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


  def handle_icmpv4_echo_request dpid, message
    interface = @interfaces.find_by_port( message.in_port )
    saddr = message.ipv4_saddr.value
    arp_entry = @arp_table.lookup( saddr )
    if arp_entry.nil?
      send_packet dpid, interface, create_arp_request( interface, saddr )
      @unresolved_packets[ saddr.value.to_i ] << message
    else
      send_packet dpid, interface, create_icmpv4_reply( arp_entry, interface, message )
    end
  end


  def should_forward? message
    @interfaces.find_by_ipaddr( message.ipv4_daddr ).nil?
  end


  def send_packet dpid, interface, packet
    send_packet_out(
      dpid,
      :data => packet,
      :actions => ActionOutput.new( :port => interface.port )
    )
  end


  def forward dpid, message
    daddr = message.ipv4_daddr.value
    nexthop = @routing_table.lookup( daddr ) 
    if nexthop.nil?
      nexthop = daddr
    end

    interface = @interfaces.find_by_prefix( nexthop )
    return if interface.nil?
    return if interface.port == message.in_port

    arp_entry = @arp_table.lookup( nexthop )
    if arp_entry.nil?
      send_packet dpid, interface, create_arp_request( interface, nexthop )
      @unresolved_packets[ nexthop.to_i ] << message
    else
      forward_packet dpid, message, interface, arp_entry.hwaddr
    end
  end


  def forward_packet dpid, message, interface, daddr
    action = interface.forward_action( daddr )
    send_flow_mod_add(
      dpid,
      :match => ExactMatch.from( message ),
      :actions => action
    )
    send_packet_out(
      dpid,
      :packet_in => message,
      :actions => action
    )
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
