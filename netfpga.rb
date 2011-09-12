require 'ffi'
require './reg_parser'

system 'gcc -c -fPIC netfpga-regset.c'                     unless File.exists? 'netfpga-regset.o'
system 'gcc -shared -o netfpga-regset.so netfpga-regset.o' unless File.exists? 'netfpga-regset.so'

class NetFPGA
  TypeNumbers = { 'silent' => 0, 'QoS' => 1, 'CAN' => 2, 'DSS' => 3, 'MGT' => 4 }

  extend FFI::Library
  ffi_lib './netfpga-regset.so'

  attach_function :get_register, [:uint],        :uint
  attach_function :set_register, [:uint, :uint], :void

  def initialize file
    @registers = RegParser.parse file
  end

  def get reg
    val = get_register @registers[reg] if File.exists? '/sys/class/net/nf2c0'
    puts "#{reg}\t->#{val}" if $debug
    val
  end

  def get_number_of_phases i
    get "SCHEDULER_#{i}_NUM_PHASES_REG"
  end

  def get_phase_length i, ph
    get "SCHEDULER_#{i}_PH_#{ph+1}_LENGTH_REG"
  end

  def get_phase_type i, ph
    get TypeNumbers.invert["SCHEDULER_#{i}_PH_#{ph+1}_TYPE_REG"]
  end

  def set reg, val
    puts "#{reg}\t<-\t#{val}" if $debug
    set_register @registers[reg], val if File.exists? '/sys/class/net/nf2c0'
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

  def set_phase_length i, ph, length
    set "SCHEDULER_#{i}_PH_#{ph+1}_LENGTH_REG", length
  end

  def set_phase_type i, ph, type
    set "SCHEDULER_#{i}_PH_#{ph+1}_TYPE_REG", TypeNumbers[type]
  end
end
