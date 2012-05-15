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


def create_arp_reply message
end


class ARPTable
  def initialize
    @arptable = Hash.new
  end


  def update message
    @arptable[ message.arp_tpa ] = message.arp_tha
  end


  def lookup ipaddr
    @arptable[ ipaddr ]
  end
end
  

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
