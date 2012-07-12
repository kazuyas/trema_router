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
require "control"
require "packet"


class Router < Controller
  add_timer_event :age_arptable, 5, :periodic      


  def start
    @control = Control.new
  end


  def packet_in dpid, message
    info "Receive packet_in."

    return if message.ipv4? == false and message.arp? == false
    return if @control.ours?( message ) == false

    if @control.is_respond?( message )
      respond dpid, message
    else
      info "forward"
      forward dpid, message
    end
  end


  def age_arptable
    @control.arptable.age
  end


  #######
  private
  #######


  def respond dpid, message
    port = message.in_port
    if message.arp_reply?
      info "Process arp reply."
      @control.arptable.update( message )
    elsif message.arp_request?
      info "Process arp request."
      interface = @control.resolve( port, message.arp_tpa )
      if interface
        send_packet dpid, port, create_arp_reply( message, interface.mac )
      end
    elsif message.icmpv4_echo_request?
      info "Process icmpv4 echo."
      send_packet dpid, port, create_icmpv4_reply( message )
    end
  end


  def send_packet dpid, out_port, packet
    send_packet_out(
      dpid,
      :data => packet,
      :actions => ActionOutput.new( :port => out_port )
    )
  end


  def forward dpid, message
    route = @control.lookup( message )
    return if route == nil

    interface = route.interface
    port = interface.port
    return if port == message.in_port

    entry = @control.arptable.lookup( route.gateway )
    if entry != nil
      forward_packet message, interface, entry.mac
    else
      info "Send arp request."
      send_packet dpid, port, create_arp_request( route )
    end
  end


  def forward_packet message, interface, daddr
    info "Forward packet."
    dpid = message.datapath_id
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
