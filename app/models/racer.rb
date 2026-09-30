class Racer < ActiveRecord::Base
  include CapitalizeAttributes

  has_many :race_entries, dependent: :destroy
  enum :gender, [:male, :female]
  capitalize_attributes :first_name, :last_name, :city
  strip_attributes collapse_spaces: true

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  before_validation do
    downcase_email
    modernize_birth_date
  end

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :gender, presence: true
  validates :email, presence: true, format: {with: VALID_EMAIL_REGEX}
  validates :birth_date, presence: true
  validates_with BirthDateValidator

  def name
    first_name + ' ' + last_name
  end

  def current_age
    now = Time.now.utc.to_date
    dob = self.birth_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def home_location
    [city.presence, state.presence].compact.join(', ')
  end

  private

  def downcase_email
    self.email = email&.downcase
  end

  def modernize_birth_date
    return unless birth_date

    if birth_date.year <= Date.today.year % 100
      self.birth_date += 2000.years
    elsif birth_date.year <= Date.today.year % 100 + 100
      self.birth_date += 1900.years
    end
  end
end
