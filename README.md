# DDC

DDC (Data Driven Controllers) let's you declare how to wire Rails into your app without the need for code. A Rails controller's job is parsing/interpreting parameters to send to your application domain and taking those results and translating them back out to an HTTP result (html/status/headers). DDC removes the need for all the boiler plate controller code and tests.

By adhering to a couple of interfaces, you can avoid writing most controller code and tests. See this [blog post]( http://spin.atomicobject.com/2015/01/26/data-driven-rails-controllers) for more information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ddc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ddc

## Usage

### Controllers

`controllers/monkeys_controller.rb`

```ruby
DDC::ControllerBuilder.build :monkeys,
  before_actions: [:authenticate_user!],
  actions: {
    show: {
      context: 'context_builder#user_and_id',
      service: 'monkey_service#find'
    },
    index: {
      context: 'context_builder#user',
      service: 'monkey_service#find_all'
    },
    update: {
      context: 'context_builder#monkey',
      service: 'monkey_service#update'
    },
    create: {
      context: 'context_builder#monkey',
      service: 'monkey_service#create'
    }
  }
```

### Context Builders
`lib/context_builder.rb`

```ruby
class ContextBuilder
  def user(context_params)
    HashWithIndifferentAccess.new current_user: context_params[:current_user] 
  end

  def user_and_id(context_params)
    user(context_params).merge(id: context_params[:params][:id])
  end

  def monkey(context_params)
    info = context_params[:params].permit(monkey: [:color, :poo])
    user_and_id(context_params).merge(info)
  end
end
```


### Services

`lib/monkeys_service.rb`

```ruby
class MonkeyService
  def find(context)
    id, user = context.values_at :id, :current_user
    me = find_for_user user, id
    if me.present?
      ok(me)
    else
      not_found
    end
  end

  def update(context)
    id, user, updates = context.values_at :id, :current_user, @model_type
    me = find_for_user user, id

    translated_updates = translated_cid_to_id(updates)
    
    if me.present?
      me.update_attributes translated_updates
      ok(me)
    else
      not_found
    end
  end

  private
  def not_found
    {status: :not_found}.freeze
  end
  def ok(obj)
    {status: :ok, object: obj}
  end
end

# shortcut for default CRUD service
MonkeyService = DDC::ServiceBuilder.build(:monkey)
```

## Contributing

1. Fork it ( https://github.com/atomicobject/ddc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
