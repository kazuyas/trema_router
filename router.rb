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
require "utils"


class Router < Controller
  include Utils


  add_timer_event :age_arp_table, 5, :periodic


  def start
    @arp_table = ARPTable.new
    @routing_table = RoutingTable.new
    @interfaces = Interfaces.new

    new_entry = Interface.new( 47, "54:00:00:01:01:01", "192.168.11.1", 24 )
    @interfaces << new_entry
    @routing_table.add( new_entry.ipaddr, new_entry.plen, nil )

    new_entry = Interface.new( 45, "54:00:00:02:02:02", "192.168.12.1", 24 )
    @interfaces << new_entry
    @routing_table.add( new_entry.ipaddr, new_entry.plen, nil )

    @routing_table.add( IPAddr.new( "192.168.13.0" ), 24, IPAddr.new( "192.168.12.2" ) )
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
    port = message.in_port
    interface = @interfaces.find_by_port( port )
    arp_entry = @arp_table.lookup( message.ipv4_saddr )
    if arp_entry.nil?
      send_packet dpid, port, create_arp_request( interface, message.ipv4_saddr )
    else
      send_packet dpid, port, create_icmpv4_reply( arp_entry, interface, message )
    end
  end


  def should_forward? message
    @interfaces.find_by_ipaddr( message.ipv4_daddr ).nil?
  end


  def send_packet dpid, out_port, packet
    send_packet_out(
      dpid,
      :data => packet,
      :actions => ActionOutput.new( :port => out_port )
    )
  end


  def forward dpid, message
    nexthop = @routing_table.lookup( message.ipv4_daddr.value )
    if nexthop.nil?
      nexthop = message.ipv4_daddr.value
    end

    interface = @interfaces.find_by_prefix( nexthop )
    return if interface.nil?

    port = interface.port
    return if port == message.in_port

    arp_entry = @arp_table.lookup( nexthop )
    if arp_entry.nil?
      send_packet dpid, port, create_arp_request( interface, nexthop )
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
