require "msgpack"

module WitnessPacker
  class OriginalPacker
    def initialize
      @factory = MessagePack::Factory.new
    end

    def pack(witness)
      packer = @factory.packer
      packer.pack(witness.id)
      packer.pack(witness.name)

      packer
    end

    def unpack(data)
      unpacker = @factory.unpacker
      unpacker.feed(data)

      Witness.new(id: unpacker.read, name: unpacker.read)
    end
  end

  class OptimalPacker
    def initialize
    end

    def pack(witness, packer)
      packer.pack(witness.id)
      packer.pack(witness.name)

      packer
    end

    def unpack(unpacker)
      Witness.new(id: unpacker.read, name: unpacker.read)
    end
  end

  class PoolPacker
    def initialize
      @factory = MessagePack::Factory.new
      @pool = @factory.pool
    end

    def pack(witness)
      @pool.packer do |packer|
        packer.pack(witness.id)
        packer.pack(witness.name)

        packer.full_pack
      end
    end

    def unpack(data)
      @pool.unpacker do |unpacker|
        unpacker.feed(data)

        Witness.new(id: unpacker.read, name: unpacker.read)
      end
    end
  end
end
