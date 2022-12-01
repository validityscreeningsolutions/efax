module EFax
  class Client
    include HTTParty

    BASE_URI     = "https://secure.efaxdeveloper.com".freeze
    SERVICE_PATH = "/EFax_WebFax.serv".freeze
    HEADERS      = {'Content-Type' => 'text/xml' }

    debug_output
    base_uri       BASE_URI
    headers        HEADERS

    class_attribute :user
    class_attribute :password
    class_attribute :account_id

    def self.params(content)
      escaped_xml = ::URI.escape(content, Regexp.new("[^#{::URI::PATTERN::UNRESERVED}]"))
      "id=#{account_id}&xml=#{escaped_xml}&respond=XML"
    end

    def self.send_request(xml)
      post(SERVICE_PATH, body: params(xml))
    end

    # private_class_method :params
  end
end
