#
# Routing Table
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


require "ipaddr"


class RouteEntry
  attr_accessor :gateway
  attr_reader :flag
  attr_reader :interface


  def initialize gateway, flag, interface
    @gateway = gateway
    @flag = flag
    @interface = interface
  end
end


class RoutingTable
  ADDR_LEN = 32


  def initialize
    @db = []
    ( 0..ADDR_LEN ).each do | plen |
      @db[ plen ] = Hash.new
    end
  end


  def add dest, plen, gateway, flag, interface
    prefix = dest.mask( plen )
    new_entry = RouteEntry.new( gateway, flag, interface )
    @db[ plen ][ prefix.to_i ] = new_entry
  end


  def delete dest, plen
    prefix = dest.mask( plen )
    @db[ plen ].delete( prefix.to_i )
  end


  def lookup dest
    ( 0..ADDR_LEN ).reverse_each do | plen |
      prefix = dest.mask( plen )
      if entry = @db[ plen ][ prefix.to_i ]
        return entry
      end
    end
    nil
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
