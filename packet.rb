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


require "router-utils"


class EthernetFrame
  attr_accessor :macda, :macsa, :eth_type
  
  
  def initialize macda, macsa, eth_type
    @macda = macda
    @macsa = macsa
    @eth_type = eth_type
  end


  def pack
    data = @macda.to_a + @macsa.to_a + [ eth_type ]
#    data.each {|each| print "#{ each.to_hex } "}
    data.pack( "C12n" )
  end
end


class ARPRequest
  attr_reader :type, :tha
  attr_accessor :sha, :tpa, :spa

  def initialize sha, tpa, spa
    @type = 1
    @tha = [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
    @sha = sha
    @tpa = tpa
    @spa = spa
  end


  def pack
    arp = ARPPacket.new( @type, @tha, @sha, @tpa, @spa )
    arp.pack
  end
end


class ARPReply
  attr_reader :type
  attr_accessor :tha, :sha, :tpa, :spa


  def initialize tha, sha, tpa, spa
    @type = 2
    @tha = tha
    @sha = sha
    @tpa = tpa
    @spa = spa
  end


  def pack
    arp = ARPPacket.new( @type, @tha, @sha, @tpa, @spa )
    arp.pack
  end
end


class ARPPacket
  attr_reader :eth_type
  attr_accessor :type, :tha, :sha, :tpa, :spa


  def initialize type, tha, sha, tpa, spa
    @eth_type = 0x0806
    @type = type
    @tha = tha
    @sha = sha
    @tpa = tpa
    @spa = spa
  end


  def pack
    frame = EthernetFrame.new( @tha, @sha, @eth_type ) 

    data = []
    # arp
    data.concat( [ 0x00, 0x01 ] ) # hardware type
    data.concat( [ 0x08, 0x00 ] ) # protocol type
    data.concat( [ 0x06 ] ) # hardware address length
    data.concat( [ 0x04 ] ) # protocol address length
    data.concat( [ 0x00, type ] ) # operation
    data.concat( @sha.to_a )
    data.concat( @spa.to_a  )
    data.concat( @tha.to_a )
    data.concat( @tpa.to_a )
    while data.length < 46 do
      data.concat( [ 0x00 ] )
    end

    frame.pack + data.pack( "C*" )
  end
end


class IPHeader
  attr_accessor :tot_len, :id, :protocol, :flags, :offset, :checksum, :daddr, :saddr

  def initialize tot_len, id, protocol, flags, offset, checksum, daddr, saddr
    @tot_len = tot_len
    @id = id
    @protocol = protocol
    @flags = flags
    @offset = offset
    @checksum = checksum
    @daddr = daddr
    @saddr = saddr
  end

  def pack
    data = []
    data.concat( [ 0x45, 0x00 ] ) # Version, IHL, ToS

    len = [ @tot_len >> 8, @tot_len & 0xff ]
    data.concat( len ) # len
    id = [ @id >> 8, @id & 0xff ]
    data.concat( id ) # ID
    data.concat( [ 0x00, 0x00 ] ) # Flags, Frag offset
    data.concat( [ 0x40, @protocol ] ) # ttl, protocol
    ipv4_checksum = [ @checksum >> 8, @checksum & 0xff ]
    data.concat( ipv4_checksum ) # checksum
    data.concat( @daddr.to_a )
    data.concat( @saddr.to_a )
    data.pack( "C*" )
    return data
  end
end


class ICMPPacket
  
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
