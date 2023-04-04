module EFax
  module Outbound
    class Disposition
      extend EFax::Inbound::Base
      extend Dry::Initializer

      def self.receive_by_xml(xml)
        doc = Hash.from_xml(xml)

        inner = doc["OutboundDisposition"].transform_keys {|k| StringUtils.snakecase(k).to_sym }

        new(**inner)
      end

      option :completion_date,  T::Params::DateTime
      option :docid,            T::Params::String
      option :duration
      option :fax_number
      option :fax_status,        T::Params::Integer
      option :number_of_retries, T::Params::Integer
      option :pages_sent,        T::Params::Integer
      option :password
      option :recipient_csid
      option :transmission_id
      option :user_name

      def success?
        fax_status.zero?
      end

      alias_method :username, :user_name
    end
  end
end
