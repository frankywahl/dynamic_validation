# frozen_string_literal: true

require "active_model"
require "active_support/core_ext/array/extract_options"
require "dynamic_validation/version"

# @author Franky W.
#
# DynamicValidation
#
# allows you to add validations at runtime # withouth having validations affect
# all of your records.
#
# @example In a Record
#
#  class MyModel < ApplicationRecord
#    include DynamicValidation
#  end
#
# @example Later in the code
#
#  my_model = MyModel.new(my_model_params)
#  my_model.add_validator { |record| record.errors.add(:foo, "bar") if record.condition? }
#  my_model.add_validators(CustomValidator, { minimum: 4 })
#
module DynamicValidation
  # add_validator is the only public method that is added
  # which allows any instance of a model to add a validator dyanmically.
  #
  # Usage
  #
  # @params args: [instance_of(ActiveModel::Validator] & arguments to the validators
  # @params &block [Proc] a block that acts as validation
  #
  #
  # @example Add a block validator
  #
  #   record.add_validator do |instance|
  #     instance.errors.add(:foo, "bar") unless instance.some_condition?
  #   end
  #
  #
  # @example ObjectValidator
  #
  #   record.add_validator(ObjectValidator)
  #
  # @example OtherObjectValidator with Arguments
  #
  #   record.add_validator(ObjectValidator, {argument_1: "a", argument_2: "b"})
  #
  # @example Array of Validators (ObjectValidator, OtherValidator)
  #
  #   record.add_validators(ObjectValidator, OtherValidator)
  def add_validators(*args, &block)
    options = args.extract_options!
    args.each do |validator|
      if !validator.new(options).respond_to?(:validate) || validator.new(options).method(:validate).arity != 1
        raise NotImplementedError, "#{validator} must implement a validate(record) method."
      end
      singleton_class.validates_with validator, options
    end

    singleton_class.validates_with BlockValidator, block: block if block_given?
  end
  alias add_validator add_validators

  # BlockValidator is a wrapper validator allow for blocks / lambda to
  # be passed at dynamically at runtime instead of having to pass in an object.
  # This will allow for quick and dirty validations, that don't need to be pulled
  # into their own objects just yet.
  class BlockValidator < ActiveModel::Validator
    def initialize(options)
      @block = options.fetch(:block)
    end

    def validate(record)
      @block.call(record)
    end
  end
end
