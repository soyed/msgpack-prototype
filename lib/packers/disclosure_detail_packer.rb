require "msgpack"

module DisclosureDetailPacker
  class OriginalPacker
    def initialize
      @factory = MessagePack::Factory.new
    end

    def pack(disclosure)
      packer = @factory.packer
      packer.pack(disclosure.id)
      packer.pack(disclosure.type)
      packer.pack(disclosure.evidence)
    end

    def unpack(data)
      unpacker = @factory.unpacker
      unpacker.feed(data)
      DisclosureDetail.new(
        id: unpacker.read,
        type: unpacker.read,
        evidence: unpacker.read
      )
    end
  end

  class OptimalPacker
    def initialize
    end

    def pack(disclosure, packer)
      packer.pack(disclosure.id)
      packer.pack(disclosure.type)
      packer.pack(disclosure.evidence)
    end

    def unpack(unpacker)
      DisclosureDetail.new(
        id: unpacker.read,
        type: unpacker.read,
        evidence: unpacker.read
      )
    end
  end

  class PoolPacker
    def initialize
      @factory = MessagePack::Factory.new
      @pool = @factory.pool
    end

    def pack(disclosure)
      @pool.packer do |packer|
        packer.pack(disclosure.id)
        packer.pack(disclosure.type)
        packer.pack(disclosure.evidence)

        packer.full_pack
      end
    end

    def unpack(data)
      @pool.unpacker do |unpacker|
        unpacker.feed(data)

        DisclosureDetail.new(
          id: unpacker.read,
          type: unpacker.read,
          evidence: unpacker.read
        )
      end
    end
  end
end
