require 'base64'
require 'tempfile'
require 'date'

module EFax
  module Inbound
    class PostRequest < Dry::Struct
      extend Base

      delegate :encoded_file_contents,
               :file_type,
               :ani,
               :account_id,
               :fax_name,
               :csid,
               :status,
               :mcfid,
               :page_count,
               :date_received,
               :barcodes,
               :barcode_pages,
           to: :fax_control

      delegate :request_type,
               :request_date,
           to: :request_control

      alias_method :sender_fax_number, :ani

      attribute :access_control do
        attribute :user_name, T::Params::String
        attribute :password,  T::Params::String
      end

      attribute :request_control do
        attribute :request_date, T::Params::DateTime
        attribute :request_type, T::Params::String
      end

      class UserField < Dry::Struct
        attribute :field_name,  T::Params::String
        attribute :field_value, T::Params::String
      end

      class FaxControl < Dry::Struct
        attribute :account_id,    T::Params::String
        attribute :fax_name,      T::Params::String
        attribute :date_received, T::Params::DateTime
        attribute :file_type,     T::Params::Symbol
        attribute :file_contents, T::Optional::String
        attribute :page_count,    T::Params::Integer
        attribute :csid,          T::Params::String
        attribute :ani,           T::Params::String
        attribute :status,        T::Params::Integer
        attribute :mcfid,         T::Params::Integer

        attribute :user_field_control do
          attribute :user_fields_read, T::Params::Integer
          attribute :user_fields do
            attribute :user_field, T::Array.of(UserField)
          end
        end

        attribute :barcode_control do
          attribute :barcodes_read, T::Params::Integer
          attribute :barcodes do
          end
        end
      end

      attribute :fax_control, FaxControl

      def file_contents
        @file_contents ||= Base64.decode64(fax_control.file_contents)
      end

      def file
        @file ||= begin
          if defined?(Encoding)
            file = Tempfile.new(fax_name, {:encoding => 'ascii-8bit'})
          else
            file = Tempfile.new(fax_name)
          end
          file << file_contents
          file.rewind
          file
        end
      end

      # def self.post_successful_message
      #   "Post Successful"
      # end

      # def self.receive_by_params(params)
      #   receive_by_xml(params[:xml] || params["xml"])
      # end

      # def self.receive_by_xml(xml)
      #   doc = nori.parse(xml)
      #   new(doc[:inbound_post_request])
      # end

      private

      def datetime_to_time(datetime)
        if datetime.respond_to?(:to_time)
          datetime.to_time
        else
          d = datetime.new_offset(0)
          d.instance_eval do
            Time.utc(year, mon, mday, hour, min, sec + sec_fraction)
          end.getlocal
        end
      end

      # def self.nori
      #   nori ||= Nori.new(convert_tags_to: lambda { |tag| StringUtils.snakecase(tag).to_sym})
      # end
    end

  end
end
