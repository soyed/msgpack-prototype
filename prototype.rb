require 'msgpack'
class DisclosureDetail
  attr_reader :id, :type, :evidence

  def initialize(id:, type:, evidence:)
    @id = id
    @type = type
    @evidence = evidence
    # this can be eliminated if we use recursive: true
    @factory = MessagePack::Factory.new
  end

  def packer(disclosure)
    packer = @factory.packer
    packer.pack(disclosure.id)
    packer.pack(disclosure.type)
    packer.pack(disclosure.evidence)
  end

  def packerRecursive(disclosure, packer)
    p packer
    packer.pack(disclosure.id)
    packer.pack(disclosure.type)
    packer.pack(disclosure.evidence)
  end

  def unpackerRecursive(unpacker)
    p unpacker
    id, type, evidence = unpacker.read, unpacker.read, unpacker.read
    puts "id: #{id}, type: #{type}, evidence: #{evidence}"
    DisclosureDetail.new(
      id: id,
      type: type,
      evidence: evidence
    )
  end

  def unpacker(data)
    unpacker = @factory.unpacker
    p unpacker
    unpacker.feed(data)
    puts unpacker.feed(data)
    DisclosureDetail.new(
      id: unpacker.read,
      type: unpacker.read,
      evidence: unpacker.read
    )
  end
end

class Agreement
  attr_reader :id, :terms, :conditions

  def initialize(id:, terms:, conditions:)
    @id = id
    @terms = terms
    @conditions = conditions
  end
end

class Disclosure
  attr_reader :id, :details

  def initialize(id:, details:, detail)
    @id = id
    @details = details
  end

  def packer(disclosure, packer)
    packer.pack(disclosure.id)
    packer.pack(disclosure.details)
  end

  def unpacker(unpacker)
    Disclosure.new(
      id: unpacker.read,
      details: unpacker.read
    )
  end
end

detail = DisclosureDetail.new(id: 1, type: 'foo', evidence: 'bar')

@factory = MessagePack::Factory.new

@bad_factory = MessagePack::Factory.new
@bad_factory.register_type(
  0x01,
  DisclosureDetail,
  packer: ->(disclosure) do
    packer = @bad_factory.packer
    packer.pack(disclosure.id)
    packer.pack(disclosure.type)
    packer.pack(disclosure.evidence)
  end,
  unpacker: ->(data) do
    unpacker = @bad_factory.unpacker
    unpacker.feed(data)
    DisclosureDetail.new(
      id: unpacker.read,
      type: unpacker.read,
      evidence: unpacker.read
    )
  end
)

@good_factory = MessagePack::Factory.new
# @@good_factory = @factory.pool
@good_factory.register_type(
  0x01,
  DisclosureDetail,
  recursive: true,
  packer: ->(disclosure, packer) do
    packer.pack(disclosure.id)
    packer.pack(disclosure.type)
    packer.pack(disclosure.evidence)
  end,
  unpacker: ->(unpacker) do
    DisclosureDetail.new(
      id: unpacker.read,
      type: unpacker.read,
      evidence: unpacker.read
    )
  end
)

# require 'benchmark/ips'
# Benchmark.ips do |x|
#   x.report("bad.dump") { @bad_factory.dump(detail) }
#   x.report("good.dump") { @good_factory.dump(detail) }
#   x.compare!(order: :baseline)
# end


# payload = @good_factory.dump(detail)
# Benchmark.ips do |x|
#   x.report("bad.load") { @bad_factory.load(payload) }
#   x.report("good.load") { @good_factory.load(payload) }
#   x.compare!(order: :baseline)
# end


# @good_factory = @good_factory.pool
# # Using pool seems to be more performant but why?
# puts "good.load: with pool"
# Benchmark.ips do |x|
#     x.report("bad.load") { @bad_factory.load(payload) }
#     x.report("good.load") { @good_factory.load(payload) }
#     x.compare!(order: :baseline)
# end

# testing what pool does
#  is #pool same as MessagePack::Factory.new?
# but instead it covers over the factory configuration from MessagePack::Factory.register_type
# @new_fact = @good_factory.pool

# p @new_fact.dump(detail)
# p @new_fact.load(payload)


# custom packer/unpacker
@bad_factory.register_type(
  0x01,
  DisclosureDetail,
  packer: detail.method(:pack),
  unpacker: detail.method(:unpack)
)

payload = @bad_factory.dump(detail)
# p @bad_factory.dump(detail)
# p @bad_factory.load(payload)

# @good_factory.register_type(
#   0x01,
#   DisclosureDetail,
#   recursive: true,
#   packer: detail.method(:packRecursive),
#   unpacker: detail.method(:unpackRecursive)
# )

# payload = @good_factory.dump(detail)
# # p @good_factory.dump(payload)
# p @good_factory.load(payload)


# Pool use case maybe
@factory.register_type(
  0x01,
  DisclosureDetail,
  recursive: true,
  packer: detail.method(:packRecursive),
  unpacker: detail.method(:unpackRecursive)
)

p @factory.dump(detail)

disclosure = Disclosure.new(id: 1, details: [detail])

@factory.register_type(
  0x02,
  Disclosure,
  recursive: true,
  packer: disclosure.method(:pack),
  unpacker: disclosure.method(:unpack)
)

p @factory.dump(disclosure)