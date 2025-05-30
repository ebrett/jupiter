require 'pundit/rspec'

RSpec.configure do |config|
  config.include Pundit::RSpec::Matchers, type: :policy
end

# Custom helper for policy testing
module PolicyTestHelpers
  def permissions(*permission_names, &block)
    permission_names.each do |permission_name|
      describe "##{permission_name}" do
        let(:policy) { described_class.new(user, record) }
        instance_eval(&block) if block_given?
      end
    end
  end
end

RSpec.configure do |config|
  config.extend PolicyTestHelpers, type: :policy
end