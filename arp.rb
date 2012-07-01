#
# ARP processing routines
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
  include Trema::Logger


  attr_reader :port
  attr_reader :mac
  attr_writer :age_max


  def initialize port, mac, age_max
    @port = port
    @mac = mac
    @age_max = age_max
    @last_updated = Time.now
    info "New entry: MAC addr = #{ @mac.to_s }, port = #{ @port }"
  end


  def update port, mac, age_max
    @port = port
    @mac = mac
    @last_updated = Time.now
    info "Update entry: MAC addr = #{ @mac.to_s }, port = #{ @port }"
  end


  def age_out?
    aged_out = Time.now - @last_update > @age_max
    aged_out
  end
end


class ARPTable
  include Trema::Logger


  DEFAULT_AGE_MAX = 300


  def initialize
    @db = {}
  end


  def update message
    entry = @db[ message.arp_spa.to_i ]
    if entry
      entry.update( message.in_port,  message.arp_sha, DEFAULT_AGE_MAX )
    else
      new_entry = ARPEntry.new( message.in_port, message.arp_sha, DEFAULT_AGE_MAX )
      @db[ message.arp_spa.to_i ] = new_entry
    end
  end


  def lookup ipaddr
    entry = @db[ ipaddr.to_i ]
    return entry
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
