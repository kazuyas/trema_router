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
  attr_reader :hwaddr
  attr_reader :ipaddr
  attr_reader :plen
  attr_reader :port


  def initialize port, hwaddr, ipaddr, plen
    @port = port
    @hwaddr = Trema::Mac.new( hwaddr )
    @ipaddr = IPAddr.new( ipaddr )
    @plen = plen
  end


  def forward_action daddr
    [
     Trema::ActionSetDlSrc.new( :dl_src => self.hwaddr ),
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


  def ours? port, hwaddr
    interface = self.find_by_port( port )
    return false if interface == nil

    if hwaddr.to_array == [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
      return true
    elsif hwaddr == interface.hwaddr
      return true
    else
      return false
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
