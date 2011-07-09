class Site
  NAMES = %w(de uk)

  def self.name
    (ENV['SITE_NAME']||'').downcase
  end

  # fast fail
  unless NAMES.include?(name)
    raise "ENV['SITE_NAME'] must contain one of #{NAMES}"
  end
  
  class << self
    # def uk? de? etc
    NAMES.each do |n|
      define_method "#{name}?" do
        name == n
      end
    end

    def smtp_settings
      {
        :user_name => ENV['HAIDB_FROM_EMAIL'],
        :password => ENV['HAIDB_FROM_PASSWD'],
        :address => "smtp.googlemail.com",
        :port => 587,
        :domain => 'haidb.info',
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    end

    def default_country
      sites = {
        'de' => 'DE',
        'uk' => 'GB'
      }
      sites[name]
    end
    
    def thankyou_url
      sites = {
        'de' => {
          # language
          :de => "http://www.liebstduschon.de/lds/index.php?id=20x0",
          :en => "http://www.liebstduschon.de/lds/index.php?id=20x1"
        },
        'uk' => {
          # fake de language to simplify code
          :de => "http://www.hai-uk.org.uk/thx.asp",
          :en => "http://www.hai-uk.org.uk/thx.asp"
        }
      }
      url = sites[name][I18n.locale]
      unless url
        raise "Missing thankyou_url for #{name}:#{I18n.locale}"
      end
      url
    end
  end
end