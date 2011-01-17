# == Schema Information
# Schema version: 20110114122352
#
# Table name: registrations
#
#  id                :integer         not null, primary key
#  angel_id          :integer         not null
#  event_id          :integer         not null
#  role              :string(255)     not null
#  special_diet      :boolean
#  backjack_rental   :boolean
#  sunday_stayover   :boolean
#  sunday_meal       :boolean
#  sunday_choice     :string(255)
#  lift              :string(255)
#  payment_method    :string(255)
#  bank_account_nr   :string(255)
#  bank_account_name :string(255)
#  bank_name         :string(255)
#  bank_sort_code    :string(255)
#  notes             :text
#  completed         :boolean
#  checked_in        :boolean
#  created_at        :datetime
#  updated_at        :datetime
#  public_signup_id  :integer
#  approved          :boolean
#

class Registration < ActiveRecord::Base
  before_save SundayChoiceCallbacks

  # role types
  PARTICIPANT = 'Participant'
  FACILITATOR = 'Facilitator'
  TEAM = 'Team'
  ROLES = [PARTICIPANT, FACILITATOR, TEAM]

  LIFTS = %w(Offered Requested)

  # payment methods. if internet the bank fields are required
  INTERNET = 'Internet'
  POST = 'Post'
  PAYMENT_METHODS = [INTERNET, POST]
  
  MEAL = "Meal"
  STAYOVER = "Stayover"
  SUNDAY_CHOICES = [MEAL, STAYOVER]

  belongs_to :angel, :inverse_of => :registrations
  belongs_to :event, :inverse_of => :registrations
  belongs_to :public_signup, :inverse_of => :registration

  accepts_nested_attributes_for :angel

  # XXX verify we need angel and action
  #attr_accessor :angel, :action

  scope :attend, includes([:angel, :event]).where(:approved => true)
  scope :pending, where(:approved => false)

  scope :team, attend.where(:role => TEAM)
  scope :participants, attend.where(:role => PARTICIPANT)
  scope :facilitators, attend.where(:role => FACILITATOR)
  
  scope :special_diets, attend.where(:special_diet => true)
  scope :backjack_rentals, attend.where(:backjack_rental => true)
  scope :sunday_stayovers, attend.where(:sunday_stayover => true)
  scope :sunday_meals, attend.where(:sunday_meal => true)
  scope :females, attend.where(:angels => {:gender => Angel::FEMALE})
  scope :males, attend.where(:angels => {:gender => Angel::MALE})
  scope :by_first_name, attend.order('LOWER(angels.first_name) asc')
  scope :by_start_date, attend.order('events.start_date desc')
  scope :completed, attend.where(:completed => true)

  validates_uniqueness_of :angel_id, {
    :scope => :event_id,
    :message => 'already registered for this event'
  }

  validates_presence_of :angel
  validates_presence_of :event, {
    :message => :select
  }

  validates_inclusion_of :role, {
    :in => ROLES, :message => :select
  }

  validates_inclusion_of :sunday_choice, {
    :in => SUNDAY_CHOICES,
    :unless => "sunday_choice.blank?"
  }

  validates_presence_of :bank_account_nr, :bank_account_name,
  :bank_name, :bank_sort_code, {
    :if => "payment_method == INTERNET"
  }

  validates_inclusion_of :payment_method, {
    :in => PAYMENT_METHODS,
    :message => :select
  }
  
  validates_inclusion_of :lift, {
    :in => LIFTS,
    :unless => "lift.blank?"
  }

  def event_name
    event.display_name
  end

  def level
    event.level
  end
  
  def full_name
    angel.full_name
  end

  def display_name
    "#{event_name} registration of #{full_name}"
  end
end
