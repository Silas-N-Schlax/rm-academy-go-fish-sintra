# Turn results class
class TurnResult
  attr_accessor :current_player, :opponent, :cards_taken,
                :card_asked_for, :card_picked_up,
                :goes_again

  def initialize(current_player:, opponent:, cards_taken:, card_asked_for:, card_picked_up:, goes_again:)
    @current_player = current_player
    @opponent = opponent
    @cards_taken = cards_taken
    @card_asked_for = card_asked_for.upcase
    @card_picked_up = card_picked_up
    @goes_again = goes_again
  end

  def question
    ["#{current_player.name} asked ", opponent.name, ' for any ', card_asked_for, 's']
  end

  def answer
    return "#{opponent.name} had #{cards_taken.length} #{card_asked_for}s" unless cards_taken.empty?

    "Go Fish: #{opponent.name} didn't have any #{card_asked_for}s"
  end

  def go_fish(name)
    return go_fish_current if name == current_player.name

    go_fish_all
  end


  private

  def go_fish_current
    return if card_picked_up.nil?

    "You drew a #{card_picked_up.rank} of #{card_picked_up.suit} #{got_what_wanted_current}"
  end

  def go_fish_all
    return if card_picked_up.nil?

    "#{current_player.name} drew a card #{got_what_wanted_all}"
  end

  def got_what_wanted_current
    "and #{goes_again ? 'get' : 'do not get'} to go again"
  end

  def got_what_wanted_all
    "and #{goes_again ? 'gets' : 'does not get'} to go again"
  end
end
