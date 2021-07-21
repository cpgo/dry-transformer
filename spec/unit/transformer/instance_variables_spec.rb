# frozen_string_literal: true

RSpec.describe Dry::Transformer, "instance methods" do
  subject(:transformer) do
    Class.new(Dry::Transformer[registry]) do
      def initialize(append_value)
        @append_value = append_value
      end
      define! do
        map_array(&:append)
      end

      def append(input)
        "#{input} #{@append_value}"
      end
    end.new("baz")
  end

  let(:registry) do
    Module.new do
      extend Dry::Transformer::Registry

      import Dry::Transformer::ArrayTransformations
    end
  end

  it "registers a new transformation function" do
    expect(transformer.call(%w[foo bar])).to eql(["foo baz", "bar baz"])
  end
end
