# hstore_radio_buttons

So, you need a bunch of radio buttons on a form. But there's no particular reason for you to save each question in its own database field. And, even better, you have access to the Hstore data type in postgres. hstore_radio_buttons is the library you are looking for. Define a set of radio buttons, display them in your form and then gather them all up and save the data in an hstore field.

# Requirements

- Postgres. If you have the hstore extension enabled, great. If not, the
  migration generated by this gem will turn it on.
- Rails 3 and the activerecord-postgres-hstore gem installed

This might work with Rails 4, which has native support for hstore, but I haven't tried that yet.

## Installation

Add this line to your application's Gemfile:

    gem 'hstore_radio_buttons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hstore_radio_buttons

hstore_radio_buttons will save all of your hstores in a single table. To
generate that table, do:

    $ rails generate hstore_radio_buttons:migration
    $ rake db:migrate

The migration does two things:

1. Executes the command "CREATE EXTENSION IF NOT EXISTS hstore"
2. Creates a polymorphic table hstore_radio_data, which is where all the
   persisted data will be saved.

If you don't need to set up the hstore extension, just remove that part
of the migration before running it.

## Usage

For every collection of radio button questions, you'll need to define their set of values as well as a label for the set of buttons. Say you want something like this:

    Gender:
      o Male
      o Female
      o Other
  
    Favorite Barn Animal:
      o Cow
      o Sheep
      o Pig

### Defining buttons in a YAML file

In above example we have two sets of buttons, one for the Gender question and one for the Barn Animal question. By default, this yaml file is stored in `config/hstore_radio_button_sets.yml`. But you can override that and put the file elsewhere, if you want.

    ---
    person:
      gender:
      - male
      - female
      - other
      'favorite barn animal':
      - cow
      - sheep
      - pig

The above defines two sets of buttons that can be used by the person model. For a model to generate/save radio button data, the set must be defined for the model.

Then set up your model so that it knows it has hstore_radio_buttons.

    class Person < ActiveRecord::Base
      include HstoreRadioButtons

      hstore_radio_buttons
      ...
    end

Changing the location of the file is done by passing in the path of your
configuration file:

    class Person < ActiveRecord::Base
      include HstoreRadioButtons

      hstore_radio_buttons './config/yamls/person_hstore_buttons.yml'
      ...
    end

### Defining buttons with macros in the model itself

Instead of using the yaml file, you can define your buttons macro-style
within the model itself.

    class Report < ActiveRecord::Base
      include HstoreRadioButtons

      hstore_radio_button Hash[viewed: ['true', 'false']]
      hstore_radio_button Hash['written by' => %w(monkeys interns milton)]
    end

### Getters, Setters, Security

Adding the button sets gives you getters and setters for those sets:

    >> p = Person.find(1)
    >> p.gender 
      => 'female'
    >> p.favorite_barn_animal
      => 'sheep'
    >> p.favorite_barn_animal = 'pig'
      => 'pig'

Keep in mind that the returned data will always be strings. So boolean
values aren't true and false, they are 'true' and 'false'. That's just
how hstore works.

And, for the sake of security, you can't set a value to
something that's not in your button definition. So if someone changes their
form submission values to include malicious data that should not be a
problem.<sup>*</sup>


    >> p = Person.find(1)
    >> p.gender = 'something hackerish' 
    >> p.gender = nil

<sup>*</sup> Notice the 'should' part there. I am not a security expert
and I welcome any pull requests that make this gem more secure.

Validations from ActiveModel work as well. So you can do:

    class Person < ActiveRecord::Base
      ...
      validates_presence_of :gender
    end

Or whatever other validations you need.

### Displaying buttons in a form

To display the radio button set on the form, you have three options:

1. Use a helper to display a single radio button
2. Use a helper to display all the radio buttons
3. Use the Rails form helpers

#### Use a helper to display a single radio button

    <%= form_for @person do |f|>
      <%= f.hstore_radio_button('gender') %>
      ...
      <%= f.hstore_radio_button(:favorite_barn_animal) %>
    <% end %>

You can use the string or a symbolized form. These are synonymous:

    <%= f.hstore_radio_button('gender') %>
    <%= f.hstore_radio_button(:gender) %>
    or
    <%= f.hstore_radio_button('Favorite Barn Animal') %>
    <%= f.hstore_radio_button(:favorite_barn_animal) %>

#### Use a helper to display all the radio buttons

    <%= form_for @person do |f|>
      <%= f.hstore_radio_buttons %>
    <% end %>

#### Use the Rails form helpers:

    <%= form_for @person do |f|>
      <%= f.label(:gender) %>
      <%= f.radio_button(:gender, 'male') %>
      <%= f.label(:gender, "Male", :value => 'male') %>
      ...
      <%= f.radio_button(:favorite_barn_animal, 'sheep') %>
      <%= f.label(:favorite_barn_animal, "Sheep", :value => 'sheep') %>
      ...
    <% end %>

If you want to avoid the duplication that the above introduces, you can
use the _options method that is added to your model:

    <%= form_for @person do |f|>
      <%= f.label(:gender) %>
      <% @person.gender_options.each do |option| %>
        <%= f.radio_button(:gender, option) %>
        <%= f.label(:gender, option.titleize, :value => option) %>
      <% end %>
    <% end %>

##### Method names when using Rails helpers
If you use the Rails helpers, you'll need to use the correct name for
the attribute. Use the lowercase, underscored version of your button set
name:

    <%= f.radio_button(:favorite_barn_animal, 'sheep') %> #works!
    <%= f.radio_button('favorite_barn_animal', 'cow') %> #works!
    <%= f.radio_button('Favorite Barn Animal', 'pig') %> #fail

### Controlling helper-created output

By default the `hstore_radio_button` or `hstore_radio_buttons` helpers
will give you output like this:

    <div>
      <label for='person_gender'>Gender</label><br />
      <input id='person_gender_male' name 'person[gender]' type='radio'
      value='male'>
      <label for='person_gender_male'>Male</label><br />
    </div>

You can swap those `<br />` tags for a different separator by passing in
your own:

    <%= f.hstore_radio_button('gender', separator: " - " %>

If you need more control, you should probably just use the Rails helpers
approach.

#### Customizing the label for a button set.

If you define a button set like this:

    person:
      gender:
      - male
      - female
      - other

And then do a render like:

    <%= f.label(:gender) %>
or

    <%= f.hstore_radio_button(:gender) %>

Then your button set will start with the label "Gender". But what if you
want something else? Use the [Rails translations api](http://guides.rubyonrails.org/i18n.html#translations-for-active-record-models). So in your en.yml file, you could put:

    en:
      activerecord:
        attributes:
          person:
            gender: "Please pick a gender"

And your radio button set will render as:

    Please pick a gender
      o Male
      o Female
      o Other 

## Persistence and Associations

The conversion of your data into an hstore is handled by
[activerecord-postgres-store]
(https://github.com/engageis/activerecord-postgres-hstore) so refer to
their documentation.

Any model that includes HstoreRadioButtons will have a has_one
associaton with `hstore_radio_data`. This relationship will have
`:autosave => true` 

As you might guess from that association, your data will be stored in 
the hstore_radio_data table. If you saved data for a Person with the 
id of 1, it will be saved as

    model_id  model_type  hstore_data
    1         Person      {'gender' => 'other'....}

But it's easiest to just work with the getters and setters in the Person
model than dealing directly with this table.

And, of course, this perisisted data is used to mark the correct radio
buttons as 'selected' when the form is loaded later.

TODO: It'd be nice to have default values for a set.  
TODO: Formtastic integration

### Thanks, etc.

Many code ideas were 'borrowed' from [Vestal
Versions](https://github.com/laserlemon/vestal_versions/) and [LRD]
(https://github.com/LRDesign). Testing and design ideas were also
contributed by [Davin Lagerroos](https://github.com/davinlagerroos).

### Versions

- 0.0.3 - Added support to customize button-set labels with Rails Internationalization API
- 0.0.2 - Fixes to inconsistency in how you call buttons by name.
- 0.0.1 - Initial

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
