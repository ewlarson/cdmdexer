require 'test_helper'

module CDMDEXER
  describe TransformationErrorMessage do
    describe 'when the error message is not a timeout' do
      it 'notifies downstream clients and does not raise an error' do
        notifier = Minitest::Mock.new
        notifier.expect :call!, nil, ['The end is nigh']
        message = 'The end is nigh'
        messenger = TransformationErrorMessage.new(message: message,
                                                   notification_klass: notifier)
        messenger.notify
      end
    end

    describe 'when the error message is a timeout' do
      it 'notifies downstream clients and does raises an error' do
        notifier = Minitest::Mock.new
        notifier.expect :call!, nil, ['Blah blah ConnectionError blah']
        message = 'Blah blah ConnectionError blah'
        messenger = TransformationErrorMessage.new(message: message,
                                                   notification_klass: notifier)
        err = ->  { messenger.notify }.must_raise RuntimeError
        err.message.must_equal 'Blah blah ConnectionError blah'
      end
    end
  end
end