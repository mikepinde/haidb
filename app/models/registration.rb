class Registration < ActiveRecord::Base
  audited
  include Mappable
  include Vcardable
  include Csvable

  csv_fields :role, :status, :full_name, :email, :gender,
             :address, :postal_code, :city, :country,
             :home_phone, :mobile_phone, :work_phone,
             :payment_method, :bank_account_name, :iban, :bic, :registration_code,
             :cost, :paid, :owed,
             :clothing_conversation, :reg_fee_received, :checked_in, :completed,
             :how_hear, :previous_event, :highest_level, :highest_location, :highest_date,
             :notes

  store :options, accessors: []

  before_save :assign_defaults, on: :create
  before_save SundayChoiceCallbacks
  before_save :update_payment_summary
  after_destroy :delete_public_signup, :update_highest_level
  after_save :update_highest_level

  STATUSES = [PENDING = 'pending', WAITLISTED = 'waitlisted', APPROVED = 'approved']

  # role types
  PARTICIPANT = 'Participant'
  FACILITATOR = 'Facilitator'
  TEAM = 'Team'
  ROLES = [PARTICIPANT, TEAM, FACILITATOR]

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

  FEMALE = 'Female'
  MALE = 'Male'
  GENDERS = [FEMALE, MALE]

  has_many :payments, dependent: :destroy
  belongs_to :angel, :inverse_of => :registrations
  belongs_to :event, :inverse_of => :registrations
  belongs_to :public_signup, :inverse_of => :registration

  scope :hai_workshops, -> { joins(:event).where(events: {category: Event::LIS}) }
  scope :where_status, ->(status) { where(status: status) }
  scope :approved, -> { where_status(APPROVED) }
  scope :pending, -> { where_status(PENDING) }
  scope :waitlisted, -> { where_status(WAITLISTED) }

  scope :ok, -> { approved }

  scope :team, -> {ok.where(:role => TEAM)}
  scope :participants, -> {ok.where(:role => PARTICIPANT)}
  scope :non_participants, -> {ok.where("role != ?", PARTICIPANT)}
  scope :non_facilitators, -> {ok.where("role != ?", FACILITATOR)}
  scope :facilitators, -> {ok.where(:role => FACILITATOR)}
  scope :where_role, lambda { |role| where(:role => role) }

  scope :where_email, ->(email) { where(email: email) }

  scope :upcoming_events, lambda { joins(:event).where('events.start_date > ?', Date.current) }
  scope :past_events, lambda { joins(:event).where('events.start_date <= ?', Date.current) }
  scope :since, lambda { |date| joins(:event).where('events.start_date >= ?', date) }
  scope :team_workshops, lambda { where(events: {category: Event::TEAM}) }

  scope :special_diets, -> { where("special_diet IS NOT NULL AND TRIM(special_diet) <> ''") }
  scope :backjack_rentals, -> {where(:backjack_rental => true)}
  scope :sunday_stayovers, -> {where(:sunday_stayover => true)}
  scope :sunday_meals, -> {where(:sunday_meal => true)}
  scope :clothing_conversations, -> {where(:clothing_conversation => true)}
  scope :reg_fee_receiveds, -> {where(:reg_fee_received => true)}
  scope :females, -> {where(:gender => FEMALE)}
  scope :males, -> {where(:gender => MALE)}
  scope :by_first_name, -> {order('LOWER(first_name) asc')}
  scope :by_start_date, -> {joins(:event).order('events.start_date desc')}
  scope :by_start_date_asc, -> {joins(:event).order('events.start_date asc')}
  scope :completed, -> {where(:completed => true)}
  scope :located_at, lambda {|lat, lng| where(lat: lat, lng: lng)}

  validates_presence_of :first_name, :last_name, :email
  validates_inclusion_of :gender, :in => GENDERS, :message => :select
  validates_inclusion_of :status, :in => STATUSES, :message => :select

  validates_uniqueness_of :event_id, scope: :angel_id, :message => :already_registered, if: ->(registration) { registration.angel }

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

  validates_numericality_of :cost, allow_nil: true

  delegate :level, :start_date, :to => :event

  REGISTRATION_FIELDS = [:first_name, :last_name, :email, :gender,
                         :address, :postal_code, :city, :country, :home_phone, :mobile_phone, :work_phone,
                         :lang, :payment_method, :bank_account_name, :iban, :bic]

  REGISTRATION_MATCH_FIELDS = REGISTRATION_FIELDS[0, 4].map(&:to_s).freeze

  STATUSES.each do |state|
    define_method("#{state}?") do
      !!(status == state)
    end
  end

  def self.move_to(angel, ids)
    where(id: ids).update_all(angel_id: angel.id) if ids.any?
  end

  def self.new_from(angel)
    registration = new(angel: angel)
    REGISTRATION_FIELDS.each do |field|
      registration.send("#{field}=", angel.send(field))
    end
    registration
  end

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def event_name
    event.display_name
  end

  def self.highest_completed_level
    completed.includes(:event).map {|r| r.event.level}.compact.max || 0
  end

  def display_name
    "#{event_name} registration of #{full_name}"
  end

  # return lang or default to 'en'
  def lang
    read_attribute(:lang) || 'en'
  end

  def iban_blurred
    'XXXXXX' + "XXX#{iban.to_s.gsub(/[^0-9]/, '')}".slice(-3,3)
  end

  def send_email(type, options = {})
    template = event.email(type, lang)
    if template
      Notifier.registration_with_template(self, template, options).deliver
    else
      logger.warn "no email template found: [#{event_name}, #{type}, #{lang}]"
    end
  end

  def update_payment_summary
    paid = payments.sum(:amount)
    self.paid = paid == 0 ? nil : paid
    owed = (cost || 0) - paid
    self.owed = (paid == 0 && owed == 0) ? nil : owed
  end

  def update_payment_summary!
    update_payment_summary
    save!
  end

  def approve
    self.status = APPROVED
  end

  def approved?
    status == APPROVED
  end

  def waitlist
    self.status = WAITLISTED
  end

  def toggle_completed
    toggle!(:completed) if approved?
  end

  def toggle_checked_in
    toggle!(:checked_in) if approved?
  end

  def assign_defaults
    assign_default_cost unless cost
    assign_registration_code if registration_code.blank?
  end

  # sort by event.start_date
  def <=>(other)
    start_date <=> other.start_date
  end

  def find_or_initialize_angel
    angel = find_matching_angel
    REGISTRATION_FIELDS.each do |field|
      angel.send("#{field}=", send(field))
    end
    self.angel = angel
  end

  private

  def find_matching_angel
    Angel.where(attributes.slice(*REGISTRATION_MATCH_FIELDS)).first_or_initialize
  end

  def update_highest_level
    angel.cache_highest_level if angel
  end

  def delete_public_signup
    PublicSignup.delete(public_signup_id) if public_signup_id
  end

  def assign_default_cost
    self.cost = event.cost_for(role) if event
  end

  def assign_registration_code
    self.registration_code = event.claim_registration_code if event
  end
end
