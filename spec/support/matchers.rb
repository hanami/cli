module RSpec
  module Support
    module Matchers
      def include_in_order(*strings)
        re = Regexp.new(
          strings.map { Regexp.escape(_1) }.join(".+"),
          Regexp::MULTILINE | Regexp::EXTENDED
        )
        match(re)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Matchers
end
