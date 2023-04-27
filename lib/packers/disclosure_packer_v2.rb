require "msgpack"
require_relative "disclosure_detail_packer"

module DisclosurePackerV2
  class OptimalPacker
    def initialize(factory:)
      @factory = factory
      disclosure_detail_packer = DisclosureDetailPacker::OptimalPacker.new
      @factory.register_type(
        0x03,
        DisclosureDetail,
        recursive: true,
        packer: ->(_packer) { raise NotImplementedError },
        unpacker: ->(unpacker) do
          puts unpacker.read
          disclosure_detail_packer.unpack(unpacker)
        end
      )
    end

    def pack(disclosure, packer)
      puts "Called disclosure packer V2"
      packer.pack(disclosure.id)
      packer.pack(disclosure.details)
    end

    def unpack(unpacker)
      Disclosure.new(id: unpacker.read, details: unpacker.read)
    end
  end
end
