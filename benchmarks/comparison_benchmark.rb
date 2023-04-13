require_relative "../lib/disclosure"
require_relative "../lib/disclosure_detail"
require_relative "../lib/witness"
require_relative "../lib/case_file"
require_relative "../lib/packers/disclosure_packer"
require_relative "../lib/packers/case_file_packer"
require "benchmark/ips"
require "stackprof"

disclosure_detail = DisclosureDetail.new(id: 1, type: "foo", evidence: "bar")
disclosure = Disclosure.new(id: 1, details: disclosure_detail)
witness = Witness.new(id: 1, name: "foo")
case_file = CaseFile.new(id: 1, disclosure: disclosure, witness: witness)

# existing pattern approach we want to improve
@original_factory = MessagePack::Factory.new
disclosure_original_packer = DisclosurePacker::OriginalPacker.new
case_file_original_packer = CaseFilePacker::OriginalPacker.new

@original_factory.register_type(
  0x01,
  Disclosure,
  packer: disclosure_original_packer.method(:pack),
  unpacker: disclosure_original_packer.method(:unpack)
)
@original_factory.register_type(
  0x02,
  CaseFile,
  packer: case_file_original_packer.method(:pack),
  unpacker: case_file_original_packer.method(:unpack)
)

# single factory approach
@optimal_factory = MessagePack::Factory.new
disclosure_optimal_packer =
  DisclosurePacker::OptimalPacker.new(factory: @optimal_factory)
case_file_optimal_packer =
  CaseFilePacker::OptimalPacker.new(factory: @optimal_factory)

@optimal_factory.register_type(
  0x01,
  Disclosure,
  recursive: true,
  packer: disclosure_optimal_packer.method(:pack),
  unpacker: disclosure_optimal_packer.method(:unpack)
)
@optimal_factory.register_type(
  0x02,
  CaseFile,
  recursive: true,
  packer: case_file_optimal_packer.method(:pack),
  unpacker: case_file_optimal_packer.method(:unpack)
)

# pool factory approach
@pool_factory = MessagePack::Factory.new
disclosure_pool_packer = DisclosurePacker::PoolPacker.new
case_file_pool_packer = CaseFilePacker::PoolPacker.new

@pool_factory.register_type(
  0x01,
  Disclosure,
  packer: disclosure_pool_packer.method(:pack),
  unpacker: disclosure_pool_packer.method(:unpack)
)
@pool_factory.register_type(
  0x02,
  CaseFile,
  packer: case_file_pool_packer.method(:pack),
  unpacker: case_file_pool_packer.method(:unpack)
)
@pool = @pool_factory.pool

puts "disclosure benchmark: serialization"
Benchmark.ips do |x|
  x.report("disclosure-optimal-approach") { @optimal_factory.dump(disclosure) }
  x.report("disclosure-pool-approach") { @pool.dump(disclosure) }
  x.compare!(order: :baseline)
end

puts "disclosure benchmark: deserialization"
disclosure_original_payload = @original_factory.dump(disclosure)
disclosure_optimal_payload = @optimal_factory.dump(disclosure)
disclosure_pool_payload = @pool.dump(disclosure)

Benchmark.ips do |x|
  x.report("disclosure-single-factory-approach") do
    @optimal_factory.load(disclosure_optimal_payload)
  end
  x.report("disclosure-pool-approach") { @pool.load(disclosure_pool_payload) }
  x.compare!(order: :baseline)
end

# puts "case file benchmark: serialization"
# Benchmark.ips do |x|
#   # x.report("case_file - original") { @original_factory.dump(case_file) }
#   x.report("case_file - optimal") { @optimal_factory.dump(case_file) }
#   x.report("case_file - pool") { @pool_factory.dump(case_file) }
#   x.compare!(order: :baseline)
# end

# puts "case file benchmark: deserialization"
# case_file_original_payload = @original_factory.dump(case_file)
# case_file_optimal_payload = @optimal_factory.dump(case_file)
# case_file_pool_payload = @pool_factory.dump(case_file)

# Benchmark.ips do |x|
#   # x.report("case_file - original") do
#   #   @original_factory.load(case_file_original_payload)
#   # end
#   x.report("case_file - optimal") do
#     @optimal_factory.load(case_file_optimal_payload)
#   end
#   x.report("case_file - pool") { @pool_factory.load(case_file_pool_payload) }
#   x.compare!(order: :baseline)
# end
