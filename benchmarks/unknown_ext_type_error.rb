require "msgpack"
require_relative "../lib/disclosure"
require_relative "../lib/disclosure_detail"
require_relative "../lib/packers/disclosure_packer"
require_relative "../lib/packers/disclosure_packer_v2"

disclosure_detail = DisclosureDetail.new(id: 1, type: "foo", evidence: "bar")
disclosure = Disclosure.new(id: 1, details: disclosure_detail)

# existing pattern approach we want to improve
factory = MessagePack::Factory.new

# the order packer versions are declared is very important
disclosure_packer_old = DisclosurePacker::OptimalPacker.new(factory: factory)
disclosure_packer_new = DisclosurePackerV2::OptimalPacker.new(factory: factory)

factory.register_type(
  0x01,
  Disclosure,
  recursive: true,
  packer: disclosure_packer_old.method(:pack),
  unpacker: disclosure_packer_old.method(:unpack)
)

factory.register_type(
  0x04,
  Disclosure,
  recursive: true,
  #   packer: disclosure_packer_new.method(:pack),
  packer: ->(_packer) { raise NotImplementedError },
  unpacker: disclosure_packer_new.method(:unpack)
)
factory.register_type(
  0x01,
  Disclosure,
  recursive: true,
  packer: disclosure_packer_old.method(:pack),
  unpacker: disclosure_packer_old.method(:unpack)
)

data = factory.dump(disclosure)
puts data
result = factory.load(data)
puts result
