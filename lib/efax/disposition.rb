module EFax
  class Disposition < Dry::Struct
    Levels = T::String.default('NONE'.freeze)
                      .enum('ERROR'   => :error,
                            'SUCCESS' => :success,
                            'BOTH'    => :both,
                            'NONE'    => :none)

    class Email < Dry::Struct
      attribute :recipient, T::String
      attribute :address, T::String
    end

    attribute  :level,  Levels
    attribute? :url,    T::String.optional
    attribute? :emails, T::Array.default(Dry::Types::EMPTY_ARRAY).of(Email)

    def method_
      if url.present?
        'POST'
      elsif emails.any?
        'EMAIL'
      else
        'NONE'
      end
    end
  end
end
