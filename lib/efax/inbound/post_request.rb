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

      delegate :user_name,
               :password,
           to: :access_control

      alias_method :sender_fax_number, :ani

      class UserField < Dry::Struct
        attribute :field_name,  T::Params::String
        attribute :field_value, T::Params::String
      end

      class UserFieldControl < Dry::Struct
        attribute :user_fields_read, T::Params::Integer
        attribute :user_fields do
          attribute :user_field, T::Array.of(UserField)
        end
      end

      class Barcode < Dry::Struct
        attribute :key, T::Params::String
        attribute :additional_info do
          attribute :read_sequence,  T::Params::Integer
          attribute :read_direction, T::Params::String
          attribute :symbology,      T::Params::String
          attribute :code_location do
            attribute :page_number, T::Params::Integer
          end
        end

        def oid = key.strip[1..]
      end

      class BarcodeControl < Dry::Struct
        attribute :barcodes_read, T::Params::Integer
        attribute :barcodes do
          attribute? :barcode, T::Array.of(Barcode) | Barcode
        end
      end

      class Page < Dry::Struct
        attribute :page_number,   T::Params::Integer
        attribute :page_contents, T::Params::String

        alias_method :number,   :page_number
        alias_method :contents, :page_contents
      end

      class PageContentControl < Dry::Struct
        attribute :pages do
          attribute :page, T::Array.of(Page) | Page
        end
      end

      class FaxControl < Dry::Struct
        attribute :account_id,     T::Params::String
        attribute :fax_name,       T::Params::String
        attribute :date_received,  T::Params::DateTime
        attribute :file_type,      T::Params::Symbol
        attribute :file_contents?, T::Optional::String
        attribute :page_count,     T::Params::Integer
        attribute :csid,           T::Params::String
        attribute :ani,            T::Params::String
        attribute :status,         T::Params::Integer
        attribute :mcfid,          T::Params::Integer

        attribute :user_field_control?,  UserFieldControl
        attribute :barcode_control,      BarcodeControl
        attribute :page_content_control, PageContentControl

        delegate :barcodes, to: :barcode_control
        delegate :pages, to: :page_content_control
      end

      attribute :access_control do
        attribute :user_name, T::Params::String
        attribute :password,  T::Params::String
      end

      attribute :request_control do
        attribute :request_date, T::Params::DateTime
        attribute :request_type, T::Params::String
      end

      attribute :fax_control, FaxControl

      def pages
        Array.wrap(fax_control.page_content_control.pages.page)
      end

      def barcodes
        Array.wrap(fax_control.barcode_control.barcodes.barcode)
      end

      def barcode_for_page(page_number)
        barcodes.find do |bc|
          bc.additional_info
            .code_location
            .page_number == page_number
        end
      end

      def document_type
        case barcodes.first&.key&.first
        when 'l' then :release
        when 's' then :results
        else :unknown
        end
      end

      def file_contents
        @file_contents ||= Base64.decode64(fax_control.file_contents)
      end

      def file
        @file ||= begin
          file = Tempfile.new(fax_name, {encoding: 'ascii-8bit'})
          file << file_contents
          file.rewind
          file
        end
      end

      def self.receive_by_xml(xml)
        doc = nori.parse(xml)
        new(doc[:inbound_post_request])
      end

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
    end
  end
end
