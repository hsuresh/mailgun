module Mailgun
  class Base
    # Options taken from
    # http://documentation.mailgun.net/quickstart.html#authentication
    # * Mailgun host - location of mailgun api servers
    # * Procotol - http or https [default to https]
    # * API key and version
    # * Test mode - if enabled, doesn't actually send emails (see http://documentation.mailgun.net/user_manual.html#sending-in-test-mode)
    # * Domain - domain to use
    def initialize(options)
      Mailgun.mailgun_host    = options.fetch(:mailgun_host)    {"api.mailgun.net"}
      Mailgun.protocol        = options.fetch(:protocol)        { "https"  }
      Mailgun.api_version     = options.fetch(:api_version)     { "v2"  }
      Mailgun.test_mode       = options.fetch(:test_mode)       { false }
      Mailgun.api_key         = options.fetch(:api_key)         { raise ArgumentError.new(":api_key is a required argument to initialize Mailgun") if Mailgun.api_key.nil?}
      @domain = options.fetch(:domain)
    end

    # Returns the base url used in all Mailgun API calls
    def base_url
      "#{Mailgun.protocol}://api:#{Mailgun.api_key}@#{Mailgun.mailgun_host}/#{Mailgun.api_version}"
    end

    # Returns an instance of Mailgun::Mailbox configured for the current API user
    def mailboxes(domain = @domain)
      Mailgun::Mailbox.new(self, domain)
    end

    def messages(domain = @domain)
      @messages ||= Mailgun::Message.new(self, domain)
    end

    def events(domain = @domain)
      @events ||= Mailgun::Event.new(self, domain)
    end

    def routes
      @routes ||= Mailgun::Route.new(self)
    end

    def bounces(domain = @domain)
      Mailgun::Bounce.new(self, domain)
    end

    def domains
      Mailgun::Domain.new(self)
    end

    def campaigns(domain = @domain)
      Mailgun::Campaign.new(self, domain)
    end

    def unsubscribes(domain = @domain)
      Mailgun::Unsubscribe.new(self, domain)
    end

    def complaints(domain = @domain)
      Mailgun::Complaint.new(self, domain)
    end

    def log(domain=@domain)
      Mailgun::Log.new(self, domain)
    end

    def lists
      @lists ||= Mailgun::MailingList.new(self)
    end

    def list_members(address)
      Mailgun::MailingList::Member.new(self, address)
    end
  end


  # Submits the API call to the Mailgun server
  def self.submit(method, url, parameters={})
    begin
      parameters = {:params => parameters} if method == :get
      return JSON(RestClient.send(method, url, parameters))
    rescue => e
      error_message = nil
      if e.respond_to? :http_body
        begin
          error_message = JSON(e.http_body)["message"]
        rescue
          raise e
        end
        raise Mailgun::Error.new(error_message)
      end
      raise e
    end
  end

  #
  # @TODO Create root module to give this a better home
  #
  class << self
    attr_accessor :api_key,
                  :api_version,
                  :protocol,
                  :mailgun_host,
                  :test_mode,
                  :domain

    def configure
      yield self
      true
    end
    alias :config :configure
  end
end
