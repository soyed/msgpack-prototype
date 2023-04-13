class DisclosureDetail
  attr_reader :id, :type, :evidence

  def initialize(id:, type:, evidence:)
    @id = id
    @type = type
    @evidence = evidence
  end
end
