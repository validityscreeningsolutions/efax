module EFax
  module Outbound
    class Status < ::EFax::Client
      extend Dry::Initializer

      option :doc_id

      def post
        response = self.class.send_request(xml)
        # OutboundStatusResponse.new(response)
      end

      def xml
        Nokogiri::XML::Builder.new do
          OutboundStatus {
            AccessControl {
              UserName user
              Password password
            }
            Transmission {
              TransmissionControl {
                DOCID doc_id
              }
            }
          }
        end.to_xml
      end

      # private_class_method :xml
    end

    class QueryStatus
      HTTP_FAILURE = 0
      PENDING      = 3
      SENT         = 4
      FAILURE      = 5
    end

    class StatusResponse
      attr_reader :status_code
      attr_reader :message
      attr_reader :classification
      attr_reader :outcome

      attr_reader :raw_response

      def initialize(response) #:nodoc:

        @raw_response = response

        if response.ok?

          pr = response.parsed_response
          tx = pr.dig('OutboundResponse', 'Transmission')

          @status_code   = tx.dig('Response', 'StatusCode').to_i
          @status_desc   = tx.dig('Response', 'StatusDescription')



          @message = doc.at(:message).innerText
          @classification = doc.at(:classification).innerText.delete('"')
          @outcome = doc.at(:outcome).innerText.delete('"')
          if !sent_yet?(classification, outcome) || busy_signal?(classification)
            @status_code = QueryStatus::PENDING
          elsif @classification == "Success" && @outcome == "Success"
            @status_code = QueryStatus::SENT
          else
            @status_code = QueryStatus::FAILURE
          end
        else
          @status_code = QueryStatus::HTTP_FAILURE
          @message = "HTTP request failed (#{response.code})"
        end
      end

      def busy_signal?(classification)
        classification == "Busy"
      end

      def sent_yet?(classification, outcome)
        !classification.empty? || !outcome.empty?
      end
    end
  end
end
