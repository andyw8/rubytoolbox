# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project::Order do
  fixtures :all

  describe described_class::Direction do
    describe "#key" do
      it "is a composite of given group and attribute" do
        expect(described_class.new(:foo, :bar).key).to be == "foo_bar"
      end

      it "can be overriden by explicit key keyword argument" do
        expect(described_class.new(:foo, :bar, key: "widgets!").key).to be == "widgets!"
      end
    end

    describe "#sql" do
      it "is constructed from pluralized group, attribute and direction" do
        expect(described_class.new(:foo, :bar).sql).to be == "foos.bar DESC NULLS LAST"
      end

      it "uses custom direction when given" do
        expect(described_class.new(:foo, :bar, direction: :asc).sql).to be == "foos.bar ASC NULLS LAST"
      end

      it "uses custom sql when given" do
        expect(described_class.new(:foo, :bar, sql: "HELLO WORLD").sql).to be == "HELLO WORLD"
      end
    end
  end

  described_class::DEFAULT_DIRECTIONS.each do |direction|
    describe "for order #{direction.key}" do
      let(:order) { described_class.new(order: direction.key) }

      it "has ordered_by #{direction.key}" do
        expect(order.ordered_by).to be == direction.key
      end

      it "has sql based on direction sql" do
        allow(direction).to receive(:sql).and_return("this sql")
        expect(order.sql).to be == "this sql"
      end

      it "returns true for is?(#{direction.key})" do
        expect(order.is?(direction.key)).to be true
      end

      it "returns false for is?('foobar')" do
        expect(order.is?("foobar")).to be false
      end
    end

    it "has a valid SQL order clause" do
      expect { Project.includes_associations.order(direction.sql).to_a }.not_to raise_error
    end
  end

  default_direction = described_class::DEFAULT_DIRECTIONS.first

  describe "for invalid order" do
    let(:order) { described_class.new(order: "lol") }

    it "has ordered_by #{default_direction.key}" do
      expect(order.ordered_by).to be == default_direction.key
    end

    it "has sql based on direction sql" do
      allow(default_direction).to receive(:sql).and_return("this sql")
      expect(order.sql).to be == "this sql"
    end
  end

  describe "#available_groups" do
    expected_groups = described_class::DEFAULT_DIRECTIONS.map(&:group).uniq

    it "has expected groups: #{expected_groups.to_sentence}" do
      expect(described_class.new(order: nil).available_groups.keys).to be == expected_groups
    end
  end

  describe "#default_direction?" do
    it "is true when the current direction is the default" do
      expect(described_class.new.default_direction?).to be true
    end

    it "is false when the current direction is not the default" do
      expect(described_class.new(order: "rubygem_downloads").default_direction?).to be false
    end
  end
end
