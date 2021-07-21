# frozen_string_literal: true
require 'pry'
RSpec.describe Dry::Transformer, "instance variables" do
  subject(:transformer) do
    Class.new(Dry::Transformer[registry]) do
      def initialize(rename_keys)
        @rename_keys = rename_keys
      end

      def my_keys
        @rename_keys
      end

      define! do
        map_array do
          rename_keys(&:my_keys)
        end
      end
    end.new("user_name" => :user)
  end

  let(:registry) do
    Module.new do
      extend Dry::Transformer::Registry

      import Dry::Transformer::HashTransformations
      import Dry::Transformer::ArrayTransformations
    end
  end

  it "registers a new transformation function" do
    expect(transformer.call([{"user_name" => "jane"}])).to eql([{user: "jane"}])
  end
end
