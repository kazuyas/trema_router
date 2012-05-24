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


require File.join( File.dirname( __FILE__ ), "spec_helper" )


require "ipaddr"
require "routing-table"


describe RoutingTable do
  before do
    @rt = RoutingTable.new
  end

  it "should be added" do
    @gateway = IPAddr.new( "192.168.1.1" )
    @rt.add( IPAddr.new( "192.168.0.0" ), 24, @gateway )
    @rt.lookup( IPAddr.new( "192.168.0.1" ) ).should == @gateway
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
