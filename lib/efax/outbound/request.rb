module EFax
  module Outbound
    class Request < ::EFax::Client
      extend Dry::Initializer

      option :name
      option :company
      option :fax_number
      option :subject
      option :files, [] do
        option :content
        option :content_type,     default: -> { :html }
        option :content_encoded,  default: -> { false }
      end
      option :disposition,      default: -> { Disposition.new }
      option :tx_control,       default: -> { TransmissionControl.new }

      def post
        response = self.class.send_request(xml)
        Response.new(response)
      end

      def xml
        Nokogiri::XML::Builder.new do
          OutboundRequest {
            AccessControl {
              UserName user
              Password password
            }
            Transmission {
              TransmissionControl {
                TransmissionID tx_control.transmission_id
                Resolution     tx_control.resolution
                Priority       tx_control.priority
                SelfBusy       tx_control.self_busy
                FaxHeader      subject
              }
              DispositionControl {
                DispositionURL    disposition.url if disposition.url.present?
                DispositionLevel  disposition.level
                unless disposition.level == 'NONE'
                  DispositionMethod disposition.method_
                  if disposition.method_ == "EMAIL"
                    DispositionEmails {
                      disposition.emails.each do |email|
                        DispositionEmail {
                          DispositionRecipient email.recipient
                          DispositionAddress   email.address
                        }
                      end
                    }
                  end
                end
              }
              Recipients {
                Recipient {
                  RecipientName    name
                  RecipientCompany company
                  RecipientFax     fax_number
                }
              }
              Files {
                files.each do |file|
                  File {
                    FileContents ensure_encoded_content(file.content, file.content_encoded)
                    FileType     file.content_type.to_s
                  }
                end
              }
            }
          }
        end.to_xml
      end

      def ensure_encoded_content(content, content_encoded)
        (content_encoded ? content : Base64.encode64(content))&.delete("\n")
      end
    end

    class RequestStatus
      HTTP_FAILURE = 0
      SUCCESS      = 1
      FAILURE      = 2
    end

    class Response
      attr_reader :status_code
      attr_reader :status_desc
      attr_reader :error_message
      attr_reader :error_level
      attr_reader :doc_id

      attr_reader :raw_response

      def initialize(response)  #:nodoc:
        @raw_response = response
        if response.ok?
          pr = response.parsed_response
          tx = pr.dig('OutboundResponse', 'Transmission')

          @status_code   = tx.dig('Response', 'StatusCode').to_i
          @status_desc   = tx.dig('Response', 'StatusDescription')
          @error_level   = tx.dig('Response', 'ErrorLevel')
          @error_message = tx.dig('Response', 'ErrorMessage')
          @doc_id        = tx.dig("TransmissionControl", 'DOCID')
        else
          @status_code = RequestStatus::HTTP_FAILURE
          @error_message = "HTTP request failed (#{response.code})"
        end
      end
    end
  end
end

