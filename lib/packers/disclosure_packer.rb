require "msgpack"
require_relative "disclosure_detail_packer"

module DisclosurePacker
  class OriginalPacker
    def initialize
      @factory = MessagePack::Factory.new
      disclosure_detail_packer = DisclosureDetailPacker::OriginalPacker.new
      @factory.register_type(
        0x01,
        DisclosureDetail,
        packer: disclosure_detail_packer.method(:pack),
        unpacker: disclosure_detail_packer.method(:unpack)
      )
    end

    def pack(disclosure)
      packer = @factory.packer
      packer.pack(disclosure.id)
      packer.pack(disclosure.details)

      packer
    end

    def unpack(data)
      unpacker = @factory.unpacker
      unpacker.feed(data)

      Disclosure.new(id: unpacker.read, details: unpacker.read)
    end
  end

  class OptimalPacker
    def initialize(factory:)
      @factory = factory
      disclosure_detail_packer = DisclosureDetailPacker::OptimalPacker.new
      @factory.register_type(
        0x02,
        DisclosureDetail,
        recursive: true,
        packer: disclosure_detail_packer.method(:pack),
        unpacker: disclosure_detail_packer.method(:unpack)
      )
    end

    def pack(disclosure, packer)
      packer.pack(disclosure.id)
      packer.pack(disclosure.details)
    end

    def unpack(unpacker)
      Disclosure.new(id: unpacker.read, details: unpacker.read)
    end
  end

  class PoolPacker
    def initialize
      @factory = MessagePack::Factory.new
      disclosure_detail_packer = DisclosureDetailPacker::PoolPacker.new
      @factory.register_type(
        0x01,
        DisclosureDetail,
        packer: disclosure_detail_packer.method(:pack),
        unpacker: disclosure_detail_packer.method(:unpack)
      )
      @pool = @factory.pool
    end

    def pack(disclosure)
      @pool.packer do |packer|
        packer.pack(disclosure.id)
        packer.pack(disclosure.details)

        packer.full_pack
      end
    end

    def unpack(data)
      @pool.unpacker do |unpacker|
        unpacker.feed(data)

        Disclosure.new(id: unpacker.read, details: unpacker.read)
      end
    end
  end
end
