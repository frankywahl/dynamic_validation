# DynamicValidation

`DynamicValidation` allows you to separate your database level validations from your business logic validation. It allows different path of your application to rely on different validations, allowing more flexibility in your app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic_validation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamic_validation

## Usage

Example:

```ruby
# app/validators/custom_validator.rb
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

# app/models/my_record.rb
class MyRecord < ApplicationRecord
  include DynamicValidation
  # ...
end

# app/controller/my_controller.rb
class MyController < ApplicationController
  def create
	record = MyRecord.new(my_record_params)

	# Add my first validator dynamically
	record.add_validator(CustomValidator, { minimum: 7 })

	# Add a block validator dynamically
	record.add_validator do |rec|
	  rec.errors.add(:field_name, "Error Message") unless rec.field_name == "NEED TO BE ME"
	end

	if record.save
	  # ...
	else
	  # ...
	end
  end

  # ...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dynamic_validation.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
