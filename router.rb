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


require "arp"
require "routing-table"
require "control"
require "packet"


class Router < Controller
  def start
    @control = Control.new
  end


  def packet_in dpid, message
    if @control.ours?( message )
      respond dpid, message
    else
      forward dpid, message
    end
  end


  #######
  private
  #######


  def respond dpid, message
    port = message.in_port
    if message.arp_reply?
      @control.arptable.update( message )
      
    elsif message.arp_request?
      addr = @control.resolve( dpid, port, message.arp_tpa )
      send_packet dpid, port, create_arp_reply( message, addr )
    elsif message.icmpv4_echo_request?
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
    ipv4_daddr = @control.rttable.lookup( message )
    egress = @control.egress( ipv4_addr )
    eth_daddr = @control.arptable.lookup( ipv4_addr )

    forward_packet egress, message, eth_daddr
  end


  def forward_packet interface, message, daddr
    dpid = message.dpid
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
