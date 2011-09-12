require 'nokogiri'

module XMLParser

  def self.parse file
    Hash[Nokogiri::XML(File.read file).xpath('/interfaces/interface').map do |interface|
      phases = interface.xpath('SchedulerXENFPG/PhaseLength').map { |p| [p.attr('pi'), p.text.to_i] }

      silent_length = interface.xpath('SchedulerXENFPG/Cyclelength').first.text.to_i - phases.map(&:last).inject(:+)

      phases << ['silent', silent_length] if silent_length > 0

      [
        interface.attr('name'),
        {
        local: interface.xpath('LinkLayerMACTransmitter/MACSourceAddress').first.text,
        other: interface.xpath('LinkLayerMACTransmitter/MACDestinationAddress').first.text,
        phases: phases,
      }
      ]
    end]
  end

end
