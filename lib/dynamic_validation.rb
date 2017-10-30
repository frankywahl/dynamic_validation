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
  def self.included(klass)
    klass.validate :dynamic_validations
  end
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
    @dynamic_validators = {} unless defined? @dynamic_validators
    options = args.extract_options!
    args.each do |validator|
      if !validator.new(options).respond_to?(:validate) || validator.new(options).method(:validate).arity != 1
        raise NotImplementedError, "#{validator} must implement a validate(record) method."
      end
      @dynamic_validators[validator] = options
    end

    add_validator Class.new(BlockValidator), block: block if block_given?
  end
  alias add_validator add_validators

  # delete_valdiators allows for a previously added validator
  # to be removed from the list of validations to be ran
  def delete_validator(validator)
    @dynamic_validators.delete(validator) if defined? @dynamic_validators
  end

  private

  def dynamic_validations
    if defined? @dynamic_validators
      @dynamic_validators.each do |validator, options|
        validates_with validator, options
      end
    end
  end

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
