module EFax
  module Inbound
    def self.post_successful_message
      "Post Successful"
    end

    module Base
      extend self

      def receive_by_params(params)
        receive_by_xml(params[:xml] || params["xml"])
      end

      def nori
        @nori ||= Nori.new(convert_tags_to: lambda { |tag| StringUtils.snakecase(tag).to_sym })
      end
    end
  end
end
