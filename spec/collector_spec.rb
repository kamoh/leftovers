require 'spec_helper'

RSpec::Matchers.define_negated_matcher :exclude, :include
RSpec.describe Forgotten::Collector do
  around { |example| with_temp_dir { example.run } }

  before { Forgotten.reset }

  it 'collects method definitions' do
    temp_file 'foo.rb', 'def m(a) a end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :m
  end

  it 'collects method calls in optional arguments' do
    temp_file 'foo.rb', 'def m(a = b) a end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :m
    expect(subject.calls).to contain_exactly :b
  end

  it 'collects method calls that match a previously defined lvar' do
    temp_file 'foo.rb', 'def m(a) self.a end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :m
    expect(subject.calls).to contain_exactly :a
  end

  it 'collects method calls using send' do
    temp_file 'foo.rb', 'send(:foo)'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :send, :foo
  end

  it 'collects method calls using send with strings' do
    temp_file 'foo.rb', 'send("foo")'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :send, :foo
  end

  it 'collects method calls using Symbol#to_proc' do
    temp_file 'foo.rb', 'array.each(&:foo)'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :array, :each, :foo
  end

  it 'collects method calls using =' do
    temp_file 'foo.rb', 'self.foo = 1'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :foo=
  end

  it 'collects method calls using +=' do
    temp_file 'foo.rb', 'self.foo += 1'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :foo=, :foo
  end

  it 'collects method calls using *=' do
    temp_file 'foo.rb', 'self.foo *= 1'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :foo=, :foo
  end

  it 'collects method calls using ||=' do
    temp_file 'foo.rb', 'self.foo ||= 1'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :foo=, :foo
  end

  it 'collects method calls using &&=' do
    temp_file 'foo.rb', 'self.foo &&= 1'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :foo=, :foo
  end

  context 'when rails' do
    before do
      temp_file '.forgotten.yml', "---\nrails: true"
      Forgotten.reset
    end

    it 'collects method calls using a method that calls multiple methods' do
      temp_file 'foo.rb', 'before_action :method_one, :method_two'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly :before_action, :method_one, :method_two
    end

    it 'collects method calls passed to before_save if:' do
      temp_file 'foo.rb', 'before_save :do_a_thing, if: :thing_to_be_done?'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly :before_save, :do_a_thing, :thing_to_be_done?
    end

    it 'collects method calls passed in an array to a before_save if:' do
      temp_file 'foo.rb', 'before_save :do_a_thing, if: [:thing_to_be_done?, :another_thing?]'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly :before_save, :do_a_thing, :thing_to_be_done?, :another_thing?
    end


    it 'collects method calls in route values' do
      temp_file 'foo.rb', 'patch :thing, to: "users#logout"'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly(:patch, :thing, :UsersController, :logout)
    end

    it 'collects scoped constant calls in class_name symbol keys' do
      temp_file 'foo.rb', 'has_many :whatever, class_name: "Which::Ever"'

      subject.collect

      expect(subject.definitions.map(&:name)).to contain_exactly(:whatever)
      expect(subject.calls).to contain_exactly(:has_many, :Which, :Ever)
    end

    it 'collects hash key calls' do
      temp_file 'foo.rb', 'validates test: true, other: :bar, presence: true'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly(:TestValidator, :validates, :OtherValidator, :PresenceValidator)
    end

    it 'collects hash key calls' do
      temp_file 'foo.rb', "get '/logout' => 'users#logout'"

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly(:UsersController, :get, :logout)
    end

    it 'collects delegation definitions and calls' do
      temp_file 'foo.rb', "delegate :foo, to: :bar"

      subject.collect

      expect(subject.definitions.map(&:name)).to contain_exactly(:foo)
      expect(subject.calls).to contain_exactly(:delegate, :bar)
    end

    it 'collects delegation definitions and calls when prefix is defined' do
      temp_file 'foo.rb', "delegate :foo, :few, prefix: :bar, to: :baz"

      subject.collect

      expect(subject.definitions.map(&:name)).to contain_exactly(:bar_foo, :bar_few)
      expect(subject.calls).to contain_exactly(:delegate, :baz)
    end

    it 'collects delegation definitions and calls when prefix is true' do
      temp_file 'foo.rb', "delegate :foo, :few, prefix: true, to: :bar"

      subject.collect

      expect(subject.definitions.map(&:name)).to contain_exactly(:bar_foo, :bar_few)
      expect(subject.calls).to contain_exactly(:delegate, :bar)
    end

    it 'collects attribute assignment args' do
      temp_file 'foo.rb', 'User.new(first_name: "Jane", last_name: "Smith")'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly(:User, :new, :first_name=, :last_name=)
    end

    it 'collects attribute assignment args' do
      temp_file 'foo.rb', 'User.create!'

      subject.collect

      expect(subject.definitions).to be_empty
      expect(subject.calls).to contain_exactly(:User, :create!)
    end
  end

  it 'copes with method calls using send with lvars' do
    temp_file 'foo.rb', 'send(foo)'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :send, :foo
  end

  it 'copes with method calls using send with interpolated lvars' do
    temp_file 'foo.rb', 'send("foo#{bar}")'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :send, :bar
  end

  it 'collects method calls that match a previously defined lvar in a different context' do
    temp_file 'foo.rb', 'def m(a) nil end; a'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :m
    expect(subject.calls).to contain_exactly :a
  end

  it 'collects constant references' do
    temp_file 'foo.rb', 'Whatever.new'

    subject.collect

    expect(subject.calls).to contain_exactly :Whatever, :new
    expect(subject.definitions).to be_empty
  end

  it 'collects class definitions' do
    temp_file 'foo.rb', 'class Whatever; end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :Whatever
    expect(subject.calls).to be_empty
  end

  it 'collects class definitions and constant calls to the inheritance class' do
    temp_file 'foo.rb', 'class Whatever < SuperClass; end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :Whatever
    expect(subject.calls).to contain_exactly :SuperClass
  end

  it 'collects module definitions' do
    temp_file 'foo.rb', 'module Whatever; end'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :Whatever
    expect(subject.calls).to be_empty
  end

  it 'collects constant assignment' do
    temp_file 'foo.rb', 'Whatever = Class.new'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly :Whatever
    expect(subject.calls).to contain_exactly :Class, :new
  end

  it 'collects haml files' do
    temp_file 'foo.haml', '= a'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:a)
  end

  it 'collects haml files with hidden scripts' do
    temp_file 'foo.haml', '- a'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly :a
  end

  it 'collects haml files string interpolation' do
    temp_file 'foo.haml', 'before#{a}after'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:a).and(exclude(:before, :after))
  end

  it 'collects haml files with ruby blocks' do
    temp_file 'foo.haml', <<~HAML
      :ruby
        a(1)
    HAML


    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:a).and(exclude(:ruby))
  end

  it 'collects haml files with dynamic attributes' do
    temp_file 'foo.haml', '%div{id: a}'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:a).and(exclude(:id, :div))
  end

  it 'collects haml files with whitespace-significant blocks' do
    temp_file 'foo.haml', <<~HAML
      - foo.each do |bar|
        = bar
    HAML

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:foo, :each).and(exclude(:bar))
  end

  it 'collects haml files with echoed whitespace-significant blocks' do
    temp_file 'foo.haml', <<~HAML
      = form_for(whatever) do |bar|
        = bar
    HAML

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to include(:form_for, :whatever).and(exclude(:bar))
  end

  it 'collects erb files' do
    temp_file 'foo.erb', '<a href="<%= whatever %>">label</a>'

    subject.collect

    expect(subject.definitions).to be_empty
    # the extra options are internal erb stuff and i don't mind
    expect(subject.calls).to include(:whatever).and(exclude(:a, :href, :label))
  end

  it 'collects erb files when newline trimmed' do
    temp_file 'foo.erb', <<~ERB
      <%- if foo.present? -%>
        <a href="<%= foo %>">label</a>
      <%- end -%>
    ERB

    subject.collect

    expect(subject.definitions).to be_empty
    # the extra options are internal erb stuff and i don't mind
    expect(subject.calls).to include(:foo, :present?).and(exclude(:a, :href, :label))
  end

  it 'collects method calls in hash values' do
    temp_file 'foo.rb', '{ call: this }'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly(:this)
  end

  it 'collects used in scope as calls' do
    temp_file 'foo.rb', 'A::B'

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly(:A, :B)
  end

  it 'collects alias method arguments' do
    temp_file 'foo.rb', 'alias_method :new_method, :original_method'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly(:new_method)
    expect(subject.calls).to contain_exactly(:alias_method, :original_method)
  end

  it "doesn't collect alias method arguments that aren't symbols" do
    temp_file 'foo.rb', <<~RUBY
      a = :whatever
      b = :whichever
      alias_method a, b
    RUBY

    subject.collect

    expect(subject.definitions).to be_empty
    expect(subject.calls).to contain_exactly(:alias_method)
  end

  it 'collects alias arguments' do
    temp_file 'foo.rb', 'alias new_method original_method'

    subject.collect

    expect(subject.definitions.map(&:name)).to contain_exactly(:new_method)
    expect(subject.calls).to contain_exactly(:original_method)
  end

  it 'collects inline comment allows' do
    temp_file 'foo.rb', <<~RUBY
      def method_name # leftovers:allow method_name
      end
    RUBY

    subject.collect
    expect(subject.definitions.map(&:name)).to contain_exactly(:method_name)
    expect(subject.calls).to contain_exactly(:method_name)
  end
end
