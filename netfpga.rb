require 'ffi'
require './reg_parser'

system 'gcc -c -fPIC netfpga-regset.c'                     unless File.exists? 'netfpga-regset.o'
system 'gcc -shared -o netfpga-regset.so netfpga-regset.o' unless File.exists? 'netfpga-regset.so'

class NetFPGA
  extend FFI::Library
  ffi_lib './netfpga-regset.so'

  attach_function :get_register, [:uint],        :uint
  attach_function :set_register, [:uint, :uint], :void

  def initialize file
    @registers = RegParser.parse file
  end

  def get reg
    get_register @registers[reg]
  end

  def set reg, val
    set_register @registers[reg], val
  end

  def set_local_mac i, mac
    ints = mac.split(':').map { |hex| hex.to_i 16 }
    set "MAC_RXTX_#{i}_LOCAL_MAC_HI_REG", ints[0] << 8 | ints[1]
    set "MAC_RXTX_#{i}_LOCAL_MAC_LO_REG", ints[2] << 24 | ints[3] << 16 | ints[4] << 8 | ints[5]
  end

  def set_number_of_phases i, number
    set "SCHEDULER_#{i}_NUM_PHASES_REG", number
  end

  def set_other_mac i, mac
    ints = mac.split(':').map { |hex| hex.to_i 16 }
    set "MAC_RXTX_#{i}_OTHER_MAC_HI_REG", ints[0] << 8 | ints[1]
    set "MAC_RXTX_#{i}_OTHER_MAC_LO_REG", ints[2] << 24 | ints[3] << 16 | ints[4] << 8 | ints[5]
  end
end


unless File.exists? '/sys/class/net/nf2c0'
  class NetFPGA
    def get reg
      puts "#{reg}\t->"
    end

    def set reg, val
      puts "#{reg}\t<-\t#{val}"
    end
  end
end
