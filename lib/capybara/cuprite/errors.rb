# frozen_string_literal: true

module Capybara
  module Cuprite
    class Error < StandardError; end
    class NoSuchWindowError < Error; end

    class ClientError < Error
      attr_reader :response

      def initialize(response)
        @response = response
      end
    end

    class BrowserError < ClientError
      def code
        response["code"]
      end

      def message
        response["message"]
      end
    end

    class JavaScriptError < ClientError
      attr_reader :class_name, :message

      def initialize(response)
        super
        @class_name, @message = response.values_at("className", "description")
      end
    end

    class StatusFailError < ClientError
      def url
        response["args"].first
      end

      def details
        response["args"][1]
      end

      def message
        msg = "Request to "#{url}" failed to reach server, check DNS and/or server status"
        msg += " - #{details}" if details
        msg
      end
    end

    class FrameNotFound < ClientError
      def name
        response["args"].first
      end

      def message
        "The frame "#{name}" was not found."
      end
    end

    class InvalidSelector < ClientError
      def initialize(response, method, selector)
        super(response)
        @method, @selector = method, selector
      end

      def message
        "Browser raised error trying to find #{@method}: #{@selector.inspect}"
      end
    end

    class NodeError < ClientError
      attr_reader :node

      def initialize(node, response)
        @node = node
        super(response)
      end
    end

    class ObsoleteNode < NodeError
      def message
        "The element you are trying to interact with is either not part of the DOM, or is " \
        "not currently visible on the page (perhaps display: none is set). " \
        "It is possible the element has been replaced by another element and you meant to interact with " \
        "the new element. If so you need to do a new find in order to get a reference to the " \
        "new element."
      end
    end

    class MouseEventFailed < NodeError
      def name
        response["args"][0]
      end

      def selector
        response["args"][1]
      end

      def position
        [response["args"][2]["x"], response["args"][2]["y"]]
      end

      def message
        "Firing a #{name} at co-ordinates [#{position.join(", ")}] failed. Cuprite detected " \
          "another element with CSS selector \"#{selector}\" at this position. " \
          "It may be overlapping the element you are trying to interact with. " \
          "If you don't care about overlapping elements, try using node.trigger(\"#{name}\")."
      end
    end

    class KeyError < ::ArgumentError
      def initialize(response)
        super(response["args"].first)
      end
    end

    class TimeoutError < Error
      def initialize(message)
        @message = message
      end

      def message
        "Timed out waiting for response to #{@message}. It's possible that this happened " \
        "because something took a very long time (for example a page load was slow). " \
        "If so, setting the Cuprite :timeout option to a higher value will help " \
        "(see the docs for details). If increasing the timeout does not help, this is " \
        "probably a bug in Cuprite - please report it to the issue tracker."
      end
    end

    class ScriptTimeoutError < Error
      def message
        "Timed out waiting for evaluated script to resturn a value"
      end
    end

    class DeadClient < Error
      def initialize(message)
        @message = message
      end

      def message
        "Browser client died while processing #{@message}"
      end
    end
  end
end
