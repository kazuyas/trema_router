def create_arp_reply message, replyaddr
  remote_nwaddr = message.arp_spa.to_array
  local_nwaddr = message.arp_tpa.to_array
  remote_dladdr = message.macsa.to_array
  local_dladdr = replyaddr.to_array
    
  data = []
  data.concat( remote_dladdr ) # dst
  data.concat( local_dladdr ) # src
  data.concat( [ 0x08, 0x06 ] )  # ether type
  # arp
  data.concat( [ 0x00, 0x01 ] ) # hardware type
  data.concat( [ 0x08, 0x00 ] ) # protocol type
  data.concat( [ 0x06 ] ) # hardware address length
  data.concat( [ 0x04 ] ) # protocol address length
  data.concat( [ 0x00, 0x02 ] ) # operation  
  data.concat( local_dladdr )
  data.concat( local_nwaddr )
  data.concat( remote_dladdr )
  data.concat( remote_nwaddr )
  while data.length < 64 do
    data.concat( [ 0x00 ] )
  end

  return data.pack( "C*" )
end

def create_icmpv4_reply message
  data = []
  data.concat( message.macsa.to_array )
  data.concat( message.macda.to_array )
  data.concat( [ message.eth_type >> 8, message.eth_type & 0xff ] )

  data.concat( [ 0x45, 0x00 ] ) # Version, IHL, ToS

  len = [ message.ipv4_tot_len >> 8, message.ipv4_tot_len & 0xff ]
  data.concat( len ) # len
  data.concat( [ 0x00, 0x00 ] ) # ID
  data.concat( [ 0x00, 0x00 ] ) # Flags, Frag offset
  data.concat( [ message.ipv4_ttl, message.ipv4_protocol ] ) # 
  

  val = message.ipv4_checksum + 0x4000
  ipv4_checksum = [  val >> 8, val & 0xff ]
  data.concat( ipv4_checksum ) #
  data.concat( message.ipv4_daddr.to_array )
  data.concat( message.ipv4_saddr.to_array )
  
  data.concat( [ 0x00, 0x00 ] ) 

  val = message.icmpv4_checksum + 0x0800
  icmp_checksum = [ val >> 8, val & 0xff ]
  data.concat( icmp_checksum )

  offset = data.length
  data.concat( message.data.unpack( "C*" )[ offset .. message.data.length ] )
 
  return data.pack( "C*" )
end
