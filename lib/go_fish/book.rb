require_relative 'card'

# Book class
class Book
  attr_reader :rank, :value

  def initialize(rank)
    @rank = rank
    @value = Card.value(rank)
  end

  def to_s
    "Book of #{Card::SPELLED_RANKS[rank]}"
  end
end
