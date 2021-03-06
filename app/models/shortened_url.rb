class ShortenedUrl < ActiveRecord::Base
  validates :short_url, :uniqueness => true, :presence => true
  validates :submitter_id, :presence => true
  validates :long_url, :presence => true

  def self.random_code
    begin
      code = SecureRandom::urlsafe_base64
    end while ShortenedUrl.exists?(:short_url => code)

    code
  end

  def self.create_for_user_and_long_url(user, long_url)
    short_url = ShortenedUrl.random_code

    ShortenedUrl.new(
      :short_url => short_url,
      :long_url  => long_url,
      :submitter_id => user.id
    )
  end

  belongs_to(
    :submitter,
    :class_name => 'User',
    :foreign_key => :submitter_id,
    :primary_key => :id
  )

  has_many(
    :visits,
    :class_name  => 'Visit',
    :foreign_key => :url_id,
    :primary_key => :id
  )

  has_many(
    :visitors,
    -> { distinct },
    :through => :visits,
    :source  => :visitor
  )

  def num_clicks
    self.visits.count
  end

  def num_uniques
    self.visitors.count
  end

  def num_recent_uniques
    self.visits
      .select(:user_id)
      .where(created_at: (10.minutes.ago)..Time.now)
      .distinct
      .count
  end

end
