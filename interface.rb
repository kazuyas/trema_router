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
require "routing-table"


class Interface
  attr_reader :hwaddr
  attr_reader :ipaddr
  attr_reader :plen
  attr_reader :port


  def initialize options = {}
    @port = options[ :port ]
    @hwaddr = Mac.new( options[ :hwaddr ] )
    @ipaddr = IPAddr.new( options[ :ipaddr ] )
    @plen = options[ :plen ]
  end


  def forward_action macda
    [
      ActionSetDlSrc.new( :dl_src => self.hwaddr ),
      ActionSetDlDst.new( :dl_dst => macda ),
      ActionOutput.new( self.port )
    ]
  end
end


class Interfaces
  def initialize interfaces
    @list = []
    interfaces.each do | each |
      self.add( each )
    end
  end

  
  def add options
    @list << Interface.new( options )
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


  def find_by_prefix ipaddr
    @list.find do | each |
      plen = each.plen
      each.ipaddr.mask( plen ) == ipaddr.mask( plen )
    end
  end


  def find_by_port_and_ipaddr port, ipaddr
    interface = @list.find do | each |
      each.port == port and each.ipaddr == ipaddr
    end
  end


  def ours? port, hwaddr
    interface = self.find_by_port( port )
    return false if interface.nil?

    if hwaddr.to_a == [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
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
