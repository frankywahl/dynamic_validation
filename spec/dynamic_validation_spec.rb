# frozen_string_literal: true

require "spec_helper"

RSpec.describe DynamicValidation do
  let(:klass) do
    Class.new do
      include ActiveModel::Validations
      include DynamicValidation
      attr_accessor :number
    end.new
  end

  class MyValidator < ActiveModel::Validator
    def validate(record)
      record.errors[:name] << "SomeError"
    end
  end

  class MyOtherValidator < ActiveModel::Validator
    def validate(record)
      record.errors[:field] << "SomeOtherError"
    end
  end

  class BadValidatorA < ActiveModel::Validator
    def validate(too, many, args); end
  end

  class CustomNumberValidator < ActiveModel::Validator
    def initialize(options)
      @options = options
    end

    def validate(record)
      if record.number <= @options.fetch(:minimum)
        record.errors.add(:number, "must be greater than #{@options[:minimum]}")
      end
    end
  end

  describe "#add_validators" do
    it "works with a single validators" do
      expect do
        klass.add_validators(MyValidator)
      end.to change { klass.valid? }.from(true).to(false)
      expect(klass.errors[:name]).to include "SomeError"
    end

    it "works with multiple validators" do
      expect do
        klass.add_validators(MyValidator, MyOtherValidator)
      end.to change { klass.valid? }.from(true).to(false)
      expect(klass.errors[:name]).to include "SomeError"
      expect(klass.errors[:field]).to include "SomeOtherError"
    end

    it "can take options" do
      klass.number = 5
      expect do
        klass.add_validator(CustomNumberValidator, minimum: 4)
      end.not_to change { klass.valid? }
      expect do
        klass.add_validator(CustomNumberValidator, minimum: 7)
      end.to change { klass.valid? }.from(true).to(false)
      expect(klass.errors[:number]).to include "must be greater than 7"
    end

    context "when passing bad parameters" do
      it "raises an errors" do
        expect { klass.add_validator(BadValidatorA) }.to raise_error NotImplementedError, "BadValidatorA must implement a validate(record) method."
      end
    end

    it "can be passed a block" do
      klass.number = 7
      expect do
        klass.add_validator do |instance|
          instance.errors.add(:foo, "bar") if instance.number < 3
        end
      end.not_to change { klass.valid? }
      expect do
        klass.add_validator do |instance|
          instance.errors.add(:foo, "bar") if instance.number < 12
        end
      end.to change { klass.valid? }.from(true).to(false)
      expect(klass.errors[:foo]).to include "bar"
    end
  end

  describe "when nothing is added" do
    it "is valid" do
      expect(klass).to be_valid
    end
  end

  it "has a version number" do
    expect(DynamicValidation::VERSION).not_to be nil
  end
end
