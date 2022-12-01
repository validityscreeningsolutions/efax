module EFax
  class TransmissionControl
    extend Dry::Initializer

    option :resolution, default: -> { 'FINE' }
    option :priority,   default: -> { 'NORMAL' }
    option :self_busy,  default: -> { 'ENABLE' }

    option :transmission_id, optional: true
  end
end
