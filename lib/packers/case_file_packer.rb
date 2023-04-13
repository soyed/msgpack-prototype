require "msgpack"
require_relative "disclosure_detail_packer"
require_relative "witness_packer"

module CaseFilePacker
  class OriginalPacker
    def initialize
      @factory = MessagePack::Factory.new
      disclosure_packer = DisclosurePacker::OriginalPacker.new
      witness_packer = WitnessPacker::OriginalPacker.new
      @factory.register_type(
        0x01,
        Disclosure,
        packer: disclosure_packer.method(:pack),
        unpacker: disclosure_packer.method(:unpack)
      )
      @factory.register_type(
        0x02,
        Witness,
        packer: witness_packer.method(:pack),
        unpacker: witness_packer.method(:unpack)
      )
    end

    def pack(case_file)
      packer = @factory.packer
      packer.pack(case_file.id)
      packer.pack(case_file.disclosure)
      packer.pack(case_file.witness)

      packer
    end

    def unpack(data)
      unpacker = @factory.unpacker
      unpacker.feed(data)

      CaseFile.new(
        id: unpacker.read,
        disclosure: unpacker.read,
        witness: unpacker.read
      )
    end
  end

  class OptimalPacker
    def initialize(factory:)
      @factory = factory
      witness_packer = WitnessPacker::OptimalPacker.new
      @factory.register_type(
        0x03,
        Witness,
        recursive: true,
        packer: witness_packer.method(:pack),
        unpacker: witness_packer.method(:unpack)
      )
    end

    def pack(case_file, packer)
      packer.pack(case_file.id)
      packer.pack(case_file.disclosure)
      packer.pack(case_file.witness)
    end

    def unpack(unpacker)
      CaseFile.new(
        id: unpacker.read,
        disclosure: unpacker.read,
        witness: unpacker.read
      )
    end
  end

  class PoolPacker
    def initialize
      @factory = MessagePack::Factory.new
      disclosure_packer = DisclosurePacker::PoolPacker.new
      witness_packer = WitnessPacker::PoolPacker.new
      @factory.register_type(
        0x01,
        Disclosure,
        packer: disclosure_packer.method(:pack),
        unpacker: disclosure_packer.method(:unpack)
      )
      @factory.register_type(
        0x02,
        Witness,
        packer: witness_packer.method(:pack),
        unpacker: witness_packer.method(:unpack)
      )
      @pool = @factory.pool
    end

    def pack(case_file)
      @pool.packer do |packer|
        packer.pack(case_file.id)
        packer.pack(case_file.disclosure)
        packer.pack(case_file.witness)

        packer.full_pack
      end
    end

    def unpack(data)
      @pool.unpacker do |unpacker|
        unpacker.feed(data)

        CaseFile.new(
          id: unpacker.read,
          disclosure: unpacker.read,
          witness: unpacker.read
        )
      end
    end
  end
end
