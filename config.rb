# -*- coding: utf-8 -*-

$interface = [
  { 
    :port => 47, 
    :hwaddr => "54:00:00:01:01:01",
    :ipaddr => "192.168.11.1",
    :plen => 24
  }, {
    :port => 45,
    :hwaddr => "54:00:00:02:02:02",
    :ipaddr => "192.168.12.1",
    :plen => 24
  }
]

$route = [
  {
    :destination => "192.168.13.0", 
    :plen => 24, 
    :gateway => "192.168.12.2" 
  }
]
