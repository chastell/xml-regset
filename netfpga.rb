require 'ffi'

system 'gcc -c -fPIC netfpga-regset.c'                     unless File.exists? 'netfpga-regset.o'
system 'gcc -shared -o netfpga-regset.so netfpga-regset.o' unless File.exists? 'netfpga-regset.so'

module NetFPGA
  extend FFI::Library
  ffi_lib './netfpga-regset.so'
  attach_function :get_register, [:uint],        :uint
  attach_function :set_register, [:uint, :uint], :void

  def self.get reg
    self.get_register $regvals[reg]
  end

  def self.set reg, val
    self.set_register $regvals[reg], val
  end
end

def NetFPGA.set_register reg, val
  puts "setting #{$regvals.invert[reg]} to val #{val}"
end unless File.exists? '/sys/class/net/nf2c0'
