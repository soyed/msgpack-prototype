require "msgpack"
require_relative "../lib/disclosure"
require_relative "../lib/disclosure_detail"
require_relative "../lib/packers/disclosure_packer"
require_relative "../lib/packers/disclosure_packer_v2"

disclosure_detail = DisclosureDetail.new(id: 1, type: "foo", evidence: "bar")
disclosure = Disclosure.new(id: 1, details: disclosure_detail)

factory = MessagePack::Factory.new

# the order packer versions are declared is very important
disclosure_packer_new = DisclosurePackerV2::OptimalPacker.new(factory: factory)
disclosure_packer_old = DisclosurePacker::OptimalPacker.new(factory: factory)

# msgpack registeration with a shared factory

# 0x01 -> Disclosure
# 0x02 -> DisclosureDetail
# 0x03 -> DisclosureDetail: packer: disabled
# 0x04 -> Disclosure => packer: disabled

# msgpack by default uses the last registed extensionType to pack and unpack

# registration order - problematic registeration order (This all happened because #initialized is called)
# old_packer ->  # 0x02 -> DisclosureDetail
# new_packer now takes precedence over old_packer. This is a problem, because msgpack can no longer pack DisclosureDetail until the new_packer is enabled)
# In other words, this registration order is a breaking change.
# new_packer ->  # 0x03 -> DisclosureDetail =>  packer: :disabled

# registration_order - How it should be registered to prevent errors
# new_packer -> # 0x03 -> DisclosureDetail => packer: :disabled (msgpack will register new pack/unpacker for DisclosureDetail but will not use it)
# old_packer -> #0x02 -> DisclosureDetail -> packer: enabled (msgpack will continue to use old_packer until I choose to enable the new_packer registered above)

# registering Disclosure
# notice how the order of registration here is
# Disclosure -> 0x04 => packer: :disabled (here, msgpack )
# Disclosure -> 0x01 -> packer: :enabled
# if registration order were reversed, it would be a breaking change
factory.register_type(
  0x04,
  Disclosure,
  recursive: true,
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
