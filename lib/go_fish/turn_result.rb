# Turn results class
class TurnResult
  attr_accessor :current_user, :opponent, :cards_taken,
                :card_asked_for, :card_picked_up,
                :goes_again

  def initialize(current_user:, opponent:, cards_taken:, card_asked_for:, card_picked_up:, goes_again:)
    @current_user = current_user
    @opponent = opponent
    @cards_taken = cards_taken
    @card_asked_for = card_asked_for.upcase
    @card_picked_up = card_picked_up
    @goes_again = goes_again
  end

  def for_current
    message_ary = [cards_taken.empty? ? for_current_got_no_cards : for_current_got_cards]
    cards_taken.each do |card|
      message_ary << "- #{card}"
    end
    message_ary
  end

  def for_all
    message_ary = [cards_taken.empty? ? for_all_got_no_cards : for_all_got_cards]
    cards_taken.each do |card|
      message_ary << "- #{card}"
    end
    message_ary
  end

  def go_fish
    "You went fishing and picked up a #{card_picked_up}. You#{goes_again ? ' ' : ' do not '}get to go again."
  end

  def went_fishing
    "#{current_user.name} went fishing, they#{goes_again ? ' ' : ' do not '}get to go again."
  end

  private

  def for_current_got_cards
    "You asked for a #{card_asked_for}, took the following from #{opponent.name}:"
  end

  def for_current_got_no_cards
    "You asked for a #{card_asked_for}, #{opponent.name} did not have any #{card_asked_for}'s."
  end

  def for_all_got_cards
    "#{current_user.name} asked for a #{card_asked_for} and took the following cards from #{opponent.name}:"
  end

  def for_all_got_no_cards
    "#{current_user.name} asked for a #{card_asked_for}, #{opponent.name} did not have any #{card_asked_for}'s."
  end
end
