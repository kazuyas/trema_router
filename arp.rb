#
# ARP processing routines
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


class ARPEntry
  attr_reader :dpid
  attr_reader :port
  attr_reader :mac
  attr_reader :ipaddr
  attr_writer :age_max


  def initialize dpid, port, mac, ipaddr, age_max
    @dpid = dpid
    @port = port
    @mac = mac
    @ipaddr = ipaddr
    @created = Time.now
  end

  
  def age_out?
    aged_out = Time.now - @created > @age_max
    aged_out
  end
end


class ARPTable
  DEFAULT_AGE_MAX = 300


  def initialize
    @arptable = {}
  end


  def update message
    @arptable[ message.arp_tpa ] = message.arp_tha # REVISIT
  end


  def lookup ipaddr
    if entry = @arptable[ ipaddr ]
      [ entry.mac, entry.port, entry.dpid ]
    else
      nil
    end
  end
end
  

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
