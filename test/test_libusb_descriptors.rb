# This file is part of Libusb for Ruby.
#
# Libusb for Ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Libusb for Ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Libusb for Ruby.  If not, see <http://www.gnu.org/licenses/>.

require "test/unit"
require "libusb"

class TestLibusbDescriptors < Test::Unit::TestCase
  include LIBUSB

  attr_accessor :usb

  def setup
    @usb = Context.new
    @usb.debug = 0
  end

  def test_descriptors
    usb.devices.each do |dev|
      assert_match(/Device/, dev.inspect, "Device#inspect should work")
      dev.configurations.each do |config_desc|
        assert_match(/Configuration/, config_desc.inspect, "ConfigDescriptor#inspect should work")
        assert dev.configurations.include?(config_desc), "Device#configurations should include this one"

        assert_kind_of Integer, config_desc.bmAttributes
        assert_kind_of Integer, config_desc.maxPower
        assert_kind_of String, config_desc.extra if config_desc.extra

        config_desc.interfaces.each do |interface|
          assert_match(/Interface/, interface.inspect, "Interface#inspect should work")

          assert dev.interfaces.include?(interface), "Device#interfaces should include this one"
          assert config_desc.interfaces.include?(interface), "ConfigDescriptor#interfaces should include this one"

          interface.alt_settings.each do |if_desc|
            assert_match(/Setting/, if_desc.inspect, "InterfaceDescriptor#inspect should work")

            assert dev.settings.include?(if_desc), "Device#settings should include this one"
            assert config_desc.settings.include?(if_desc), "ConfigDescriptor#settings should include this one"
            assert interface.alt_settings.include?(if_desc), "Inteerface#alt_settings should include this one"

            if_desc.endpoints.each do |ep|
              assert_match(/Endpoint/, ep.inspect, "EndpointDescriptor#inspect should work")

              assert dev.endpoints.include?(ep), "Device#endpoints should include this one"
              assert config_desc.endpoints.include?(ep), "ConfigDescriptor#endpoints should include this one"
              assert interface.endpoints.include?(ep), "Inteerface#endpoints should include this one"
              assert if_desc.endpoints.include?(ep), "InterfaceDescriptor#endpoints should include this one"

              assert_equal if_desc, ep.setting, "backref should be correct"
              assert_equal interface, ep.interface, "backref should be correct"
              assert_equal config_desc, ep.configuration, "backref should be correct"
              assert_equal dev, ep.device, "backref should be correct"

              assert_operator 0, :<, ep.wMaxPacketSize, "packet size should be > 0"
            end
          end
        end
      end
    end
  end

  def test_constants
    assert_equal 7, CLASS_PRINTER, "Printer class id should be defined"
    assert_equal 48, ISO_USAGE_TYPE_MASK, "iso usage type should be defined"
  end

  def test_device_filter_mass_storages
    devs1 = []
    usb.devices.each do |dev|
      dev.settings.each do |if_desc|
        if if_desc.bInterfaceClass == CLASS_MASS_STORAGE &&
              ( if_desc.bInterfaceSubClass == 0x01 ||
                if_desc.bInterfaceSubClass == 0x06 ) &&
              if_desc.bInterfaceProtocol == 0x50

          devs1 << dev
        end
      end
    end

    devs2 =  usb.devices( :bClass=>CLASS_MASS_STORAGE, :bSubClass=>0x01, :bProtocol=>0x50 )
    devs2 += usb.devices( :bClass=>CLASS_MASS_STORAGE, :bSubClass=>0x06, :bProtocol=>0x50 )
    assert_equal devs1.sort, devs2.sort, "devices and devices with filter should deliver the same device"

    devs3 =  usb.devices( :bClass=>[CLASS_MASS_STORAGE], :bSubClass=>[0x01,0x06], :bProtocol=>[0x50] )
    assert_equal devs1.sort, devs3.sort, "devices and devices with array-filter should deliver the same device"
  end

  def test_device_filter_hubs
    devs1 = []
    usb.devices.each do |dev|
      dev.settings.each do |if_desc|
        if if_desc.bInterfaceClass == CLASS_HUB
          devs1 << dev
        end
      end
    end

    devs2 = usb.devices( :bClass=>CLASS_HUB )
    assert_equal devs1.sort, devs2.sort, "devices and devices with filter should deliver the same device"
  end

  def test_device_methods
    usb.devices.each do |dev|
      ep = dev.endpoints.first
      if ep
        assert_operator dev.max_packet_size(ep), :>, 0, "#{dev.inspect} should have a usable packet size"
        assert_operator dev.max_packet_size(ep.bEndpointAddress), :>, 0, "#{dev.inspect} should have a usable packet size"
        assert_operator dev.max_iso_packet_size(ep), :>, 0, "#{dev.inspect} should have a usable iso packet size"
        assert_operator dev.max_iso_packet_size(ep.bEndpointAddress), :>, 0, "#{dev.inspect} should have a usable iso packet size"
      end
    end
  end
end
