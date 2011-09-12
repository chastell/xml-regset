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
