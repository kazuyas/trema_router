def create_ether_header macda, macsa, eth_type
  data = []
  data.concat( macda ) # dst
  data.concat( macsa ) # src
  data.concat( eth_type ) # eth_type
  return data.pack( "C*" )
end


def create_arp_packet type, spa, sha, tpa, tha
  data = create_ether_header( tha, sha, [ 0x08, 0x06 ] )
  # arp
  data.concat( [ 0x00, 0x01 ] ) # hardware type
  data.concat( [ 0x08, 0x00 ] ) # protocol type
  data.concat( [ 0x06 ] ) # hardware address length
  data.concat( [ 0x04 ] ) # protocol address length
  data.concat( [ 0x00, type ] ) # operation
  data.concat( sha )
  data.concat( spa )
  data.concat( tha )
  data.concat( tpa )
  while data.length < 64 do
    data.concat( [ 0x00 ] )
  end

  return data.pack( "C*" )
end


def create_arp_request route
  interface = route.interface
  spa = interface.ipaddr
  sha = interface.mac

  tpa = route.gateway.to_array
  tha = [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]

  return create_arp_packet 0x1, spa, sha, tpa, tha
end


def create_arp_reply message, replyaddr
  spa = message.arp_tpa.to_array
  sha = replyaddr.to_array

  tpa = message.arp_spa.to_array
  tha = message.macsa.to_array

  return create_arp_packet 0x2, spa, sha, tpa, tha
end


def create_ipv4_header message
  data = []
  data.concat( [ 0x45, 0x00 ] ) # Version, IHL, ToS

  len = [ message.ipv4_tot_len >> 8, message.ipv4_tot_len & 0xff ]
  data.concat( len ) # len
  data.concat( [ 0x00, 0x00 ] ) # ID
  data.concat( [ 0x00, 0x00 ] ) # Flags, Frag offset
  data.concat( [ 0x40, message.ipv4_protocol ] ) # ttl, protocol

  val = message.ipv4_checksum + 0x4000
  ipv4_checksum = [  val >> 8, val & 0xff ]
  data.concat( ipv4_checksum ) #
  data.concat( message.ipv4_daddr.to_array )
  data.concat( message.ipv4_saddr.to_array )
  return data.pack( "C*" )
end


def create_icmpv4_reply message
  data = create_ether_header( message.macsa.to_array, message.macda.to_array, [ 0x80, 0x00 ] )

  data.concat( create.ipv4_header( message ) )

  data.concat( [ 0x00, 0x00 ] )

  val = message.icmpv4_checksum + 0x0800
  icmp_checksum = [ val >> 8, val & 0xff ]
  data.concat( icmp_checksum )

  offset = data.length
  data.concat( message.data.unpack( "C*" )[ offset .. message.data.length ] )

  return data.pack( "C*" )
end
