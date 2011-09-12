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
    val = live? ? get_register(@registers[reg]) : 0
    puts "\t\t#{reg}\t->\t#{val}" if $debug
    val
  end

  def set reg, val
    puts "\t\t#{reg}\t<-\t#{val}" if $debug
    set_register @registers[reg], val if live?
  end

  def live?
    File.exists? '/sys/class/net/nf2c0'
  end

  def get_mac i, loc_oth
    hi = get "MAC_RXTX_#{i}_#{loc_oth.upcase}_MAC_HI_REG"
    lo = get "MAC_RXTX_#{i}_#{loc_oth.upcase}_MAC_LO_REG"
    ints = [(hi & 0xff00) >> 8, hi & 0xff, (lo & 0xff000000) >> 24, (lo & 0xff0000) >> 16, (lo & 0xff00) >> 8, lo & 0xff]
    ints.map { |i| i.to_s(16).rjust 2, '0'}.join ':'
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

  def set_mac i, loc_oth, mac
    ints = mac.split(':').map { |hex| hex.to_i 16 }
    set "MAC_RXTX_#{i}_#{loc_oth.upcase}_MAC_HI_REG", ints[0] << 8 | ints[1]
    set "MAC_RXTX_#{i}_#{loc_oth.upcase}_MAC_LO_REG", ints[2] << 24 | ints[3] << 16 | ints[4] << 8 | ints[5]
  end

  def set_number_of_phases i, number
    set "SCHEDULER_#{i}_NUM_PHASES_REG", number
  end

  def set_phase_length i, ph, length
    set "SCHEDULER_#{i}_PH_#{ph+1}_LENGTH_REG", length
  end

  def set_phase_type i, ph, type
    set "SCHEDULER_#{i}_PH_#{ph+1}_TYPE_REG", TypeNumbers[type]
  end

end
