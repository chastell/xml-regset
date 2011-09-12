module RegParser

  def self.parse file
    Hash[File.read(file).scan(/^#define\s+(\S+)\s+(\S+)$/).map do |reg, val|
      [
        reg,
        case val
        when /^\d+$/          then val.to_i
        when /^0x[0-9a-f]+$/i then val.to_i 16
        else                       val
        end
      ]
    end]
  end

end
