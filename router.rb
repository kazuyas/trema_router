require "arp"
require "icmp"
require "routetable"


class Router < Controller


  def start
    @arptable = ARPTable.new
  end


  def packet_in dpid, message
    if ours?( message )
      process dpid, message
    else
      forward dpid, message
    end
  end


  #######
  private
  #######


  def process dpid, message
    if message.arp_request?
      send_packet dpid, message.in_port, create_arp_reply( message )
    elsif message.arp_reply?
      @arptable.update( message )
    elsif message.icmp_echo_request?
      send_packet dpid, message.in_port, create_icmp_reply( message )
    end
  end


  def send_packet dpid, out_port, message
  end


  def forward dpid, message
  end


end
