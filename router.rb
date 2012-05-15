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
require "icmp"
require "routetable"


class Router < Controller


  def start
    @arptable = ARPTable.new
  end


  def packet_in dpid, message
    if ours?( message )
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
      @arptable.update( message )
    elsif message.arp_request?
      send_packet dpid, port, create_arp_reply( message )
    elsif message.icmpv4_echo_request?
      send_packet dpid, port, create_icmpv4_reply( message )
    end
  end


  def send_packet dpid, out_port, frame
    send_packet_out(
      dpid,
      :data => frame,
      :actions => ActionOutput.new( :port => out_port )
    )
  end


  def forward dpid, message
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
