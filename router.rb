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
require "interface"
require "packet"


class Router < Controller
  add_timer_event :age_arptable, 5, :periodic


  def start
    @arptable = ARPTable.new
    @rttable = RoutingTable.new
    @iftable = Interfaces.new

    new_entry = Interface.new( 47, "54:00:00:01:01:01", "192.168.11.1", 24 )
    @iftable << new_entry
    @rttable.add( new_entry.ipaddr, new_entry.plen, nil, new_entry )

    new_entry = Interface.new( 46, "54:00:00:02:02:02", "192.168.12.1", 24 )
    @iftable << new_entry
    @rttable.add( new_entry.ipaddr, new_entry.plen, nil, new_entry )

    @rttable.add( IPAddr.new( "192.168.13.0" ), 24,
                  IPAddr.new( "192.168.12.2" ), new_entry )
  end


  def packet_in dpid, message
    info "Receive packet_in."

    return if @iftable.ours?( message.in_port, message.macda ) == false

    if message.arp_request?
      proc_arp_request( dpid, message )
    elsif message.arp_reply?
      proc_arp_reply( dpid, message )
    elsif message.ipv4?
      proc_ipv4( dpid, message )
    end
  end


  def age_arptable
    @arptable.age
  end


  #######
  private
  #######


  def proc_arp_request dpid, message
    info "Process arp request."
    port = message.in_port
    interface = @iftable.find_by_port_and_ipaddr( port, message.arp_tpa )
    if interface
      send_packet dpid, port, create_arp_reply( message, interface.hwaddr )
    end
  end


  def proc_arp_reply dpid, message
    info "Process arp reply."
    @arptable.update( message.in_port, message.arp_spa, message.arp_sha )
  end


  def proc_ipv4 dpid, message
    if should_forward?( message )
      info "Forward packets."
      forward dpid, message
    elsif message.icmpv4_echo_request?
      proc_icmpv4_echo_request dpid, message
    end
  end


  def proc_icmpv4_echo_request dpid, message
    info "Process icmpv4 echo request."

    port = message.in_port
    interface = @iftable.find_by_port( port )
    entry = @arptable.lookup( message.ipv4_saddr )
    if entry == nil
      info "Send arp request."
      send_packet dpid, port, create_arp_request( interface, message.ipv4_saddr )
    else
      send_packet dpid, message.in_port, create_icmpv4_reply( entry, interface, message )
    end
  end


  def should_forward? message
    @iftable.find_by_ipaddr( message.ipv4_daddr ) == nil
  end


  def send_packet dpid, out_port, packet
    send_packet_out(
      dpid,
      :data => packet,
      :actions => ActionOutput.new( :port => out_port )
    )
  end


  def forward dpid, message
    route = @rttable.lookup( message.ipv4_daddr.value )
    return if !route
    if !route.gateway
      route.gateway = message.ipv4_daddr.value
    end

    interface = route.interface
    port = interface.port
    return if port == message.in_port

    entry = @arptable.lookup( route.gateway )
    if entry == nil
      info "Send arp request."
      send_packet dpid, port, create_arp_request( interface, route.gateway )
    else
      forward_packet dpid, message, interface, entry.hwaddr
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
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
