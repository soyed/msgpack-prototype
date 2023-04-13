class CaseFile
  attr_reader :id, :disclosure, :witness

  def initialize(id:, disclosure:, witness:)
    @id = id
    @disclosure = disclosure
    @witness = witness
  end
end
