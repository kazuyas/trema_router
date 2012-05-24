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


class RoutingTable
  ADDR_LEN = 32


  def initialize
    @db = []
    [ 0..ADDR_LEN ].each do | prefixlen |
      @db[ prefixlen ] = Hash.new
    end
  end


  def add prefix, prefixlen, gateway
    raise "assert" if @db[ prefixlen ] == nil
    @db[ prefixlen ][ prefix.to_i ] = gateway
  end


  def delete prefix, prefixlen
    @db[ prefixlen ].delete( prefix.to_i )
  end

  
  def lookup destination
    [ 0..ADDR_LEN ].each do | i |
      prefixlen = ADDR_LEN - i
      prefix = mask( destination, prefixlen )
      if gateway = @db[ prefixlen ][ prefix.to_i ]
        return gateway
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
