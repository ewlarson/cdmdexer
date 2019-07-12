module CDMDEXER
  # Raise anything but timeout errors or other http connection errors
  # Notify downstream in case users want to log the non-timeout errors
  class TransformationErrorMessage
    attr_reader :message, :notification_klass
    def initialize(message: :MISSING_ERROR_MESSAGE,
                   notification_klass: CDMDEXER::CdmError)
      @notification_klass = notification_klass
      @message = message
    end

    def notify
      notification_klass.call! message
      raise message if http_error?
    end

    private

    def http_error?
      !(message =~ /ConnectionError/).nil?
    end
  end
end
