class Disclosure
  attr_reader :id, :details

  def initialize(id:, details:)
    @id = id
    @details = details
  end
end
