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
    @gateway11 = IPAddr.new( "192.168.1.1" )
    @gateway12 = IPAddr.new( "192.168.1.2" )

    @dest00 = IPAddr.new( "192.168.0.0" )
    @dest01 = IPAddr.new( "192.168.0.1" )
    @dest02 = IPAddr.new( "192.168.0.2" )
    @dest11 = IPAddr.new( "192.168.1.1" )
    @dest21 = IPAddr.new( "192.168.2.1" )
  end


  it "should be answered" do
    @rt.add( :destination => "192.168.0.1", 
             :plen => 32, 
             :gateway => "192.168.1.1" )
    @rt.lookup( @dest01 ).to_s.should == "192.168.1.1"
  end


  it "should be answered the longest matched gateway" do
    @rt.add( :destination => "192.168.0.1", 
             :plen => 32, 
             :gateway => "192.168.1.1" )
    @rt.add( :destination => "192.168.0.0", 
             :plen => 24, 
             :gateway => "192.168.1.2" )

    @rt.lookup( @dest01 ).to_s.should == "192.168.1.1"
    @rt.lookup( @dest02 ).to_s.should == "192.168.1.2"
  end


  it "should not be answered if unmatched" do
    @rt.add( :destination => "192.168.0.1", 
             :plen => 32, 
             :gateway => "192.168.1.1" )
    @rt.lookup( @dest21 ).should == nil
  end


  it "should not be answered if empty" do
    @rt.lookup( @dest21 ).should == nil
  end


  it "can delete an entry" do
    @rt.add( :destination => "192.168.0.1", 
             :plen => 32, 
             :gateway => "192.168.1.1" )
    @rt.add( :destination => "192.168.0.0", 
             :plen => 24, 
             :gateway => "192.168.1.2" )
    @rt.lookup( @dest01 ).to_s.should == "192.168.1.1"

    @rt.delete( :destination => "192.168.0.1", 
                :plen => 32 )
    @rt.lookup( @dest01 ).to_s.should == "192.168.1.2"
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
