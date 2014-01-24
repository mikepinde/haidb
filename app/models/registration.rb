class Registration < ActiveRecord::Base
  acts_as_audited
  acts_as_gmappable lat: 'lat', lng: 'lng', process_geocoding: false

  has_many :payments, dependent: :destroy

  store :options, accessors: [:highest_level, :highest_location, :highest_date, :registration_code]

  before_save SundayChoiceCallbacks
  before_save :update_payment_summary
  before_save :assign_registration_code, if: lambda {|r| r.approved? && r.event.has_registration_codes? && r.registration_code.blank? }
  after_destroy :delete_public_signup

  # role types
  PARTICIPANT = 'Participant'
  FACILITATOR = 'Facilitator'
  TEAM = 'Team'
  ROLES = [PARTICIPANT, FACILITATOR, TEAM]

  OFFERED = 'Offered'
  REQUESTED = 'Requested'
  LIFTS = [OFFERED, REQUESTED]

  # payment methods. if debt the bank fields are required
  PAY_DEBT = 'Debt'
  PAY_TRANSFER = 'Transfer'
  PAYMENT_METHODS = [PAY_DEBT, PAY_TRANSFER]
  
  MEAL = "Meal"
  STAYOVER = "Stayover"
  SUNDAY_CHOICES = [MEAL, STAYOVER]

  HOW_HEAR = ['Friend', 'Advertisement', 'Web Search', 'Enquired Nov 2010 Priceless wksp']
  PREVIOUS_EVENT = ['No', 'Intro', 'Mini-workshop', 'Open Community Day', 'Weekend Workshop']

  belongs_to :angel, :inverse_of => :registrations
  belongs_to :event, :inverse_of => :registrations
  belongs_to :public_signup, :inverse_of => :registration

  accepts_nested_attributes_for :angel

  scope :ok, includes([:angel, :event]).where(:approved => true)
  scope :pending, where(:approved => false)

  scope :team, ok.where(:role => TEAM)
  scope :participants, ok.where(:role => PARTICIPANT)
  scope :non_participants, ok.where("role != ?", PARTICIPANT)
  scope :non_facilitators, ok.where("role != ?", FACILITATOR)
  scope :facilitators, ok.where(:role => FACILITATOR)
  scope :where_role, lambda { |role| ok.where(:role => role) }

  scope :where_email, lambda { |email| includes([:angel, :event]).where('angels.email = ?', email) }

  scope :upcoming_events, lambda { includes(:event).where('events.start_date > ?', Date.current) }
  scope :past_events, lambda { includes(:event).where('events.start_date <= ?', Date.current) }
  scope :since, lambda { |date| includes(:event).where('events.start_date >= ?', date) }
  scope :team_workshops, lambda { where(events: {category: Event::TEAM}) }

  scope :special_diets, where(:special_diet => true)
  scope :backjack_rentals, where(:backjack_rental => true)
  scope :sunday_stayovers, where(:sunday_stayover => true)
  scope :sunday_meals, where(:sunday_meal => true)
  scope :clothing_conversations, where(:clothing_conversation => true)
  scope :reg_fee_receiveds, where(:reg_fee_received => true)
  scope :females, where(:angels => {:gender => Angel::FEMALE})
  scope :males, where(:angels => {:gender => Angel::MALE})
  scope :by_first_name, includes(:angel).order('LOWER(angels.first_name) asc')
  scope :by_start_date, includes(:event).order('events.start_date desc')
  scope :by_start_date_asc, includes(:event).order('events.start_date asc')
  scope :completed, where(:completed => true)

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

  validates_presence_of :bank_account_name, :iban, :bic, if: lambda {|r| r.payment_method == PAY_DEBT }

  validates_inclusion_of :lift, {
    :in => LIFTS,
    :unless => "lift.blank?"
  }

  validates_numericality_of :cost

  delegate :level, :start_date, :to => :event
  delegate :lat, :lng, :full_name, :gender, :email, :to => :angel
  
  def event_name
    event.display_name
  end

  def self.highest_completed_level
    completed.includes(:event).map {|r| r.event.level}.compact.max || 0
    #maximum('events.level', :include => :event, :conditions => {
    #          :completed => true,
    #        }).to_i
  end

  def display_name
    "#{event_name} registration of #{full_name}"
  end

  # return angel lang or default to 'en'
  def lang
    (angel && angel.lang) || 'en'
  end

  def send_email(type)
    template = event.email(type, lang)
    if template
      Notifier.registration_with_template(self, template).deliver
    else
      logger.warn "no email template found: [#{event_name}, #{type}, #{lang}]"
    end
  end

  def pending?
    !approved?
  end

  def update_payment_summary
    self.paid = payments.sum(:amount) || 0
    self.cost ||= 0
    self.owed = cost - paid
  end

  def update_payment_summary!
    update_payment_summary
    save!
  end

  def approve
    self.approved = true
  end

  def assign_default_cost
    self.cost = event.cost_for(role) if event
  end

  private

  def delete_public_signup
    PublicSignup.delete(public_signup_id) if public_signup_id
  end

  def assign_registration_code
    self.registration_code = event.claim_registration_code
  end
end
