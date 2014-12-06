require 'spec_helper'
require 'settings_bag'

describe SettingsBag do
  let(:hsh) {{
    foo: 1,
    bar: {
      baz: 2
    }
  }}

  subject { described_class.new(hsh) }

  describe 'dynamic methods' do

    context "when ENV var is not present" do
      describe "#foo" do
        it "returns 1" do
          expect(subject.foo).to eq(1)
        end
      end
    end

  end

  describe '#respond_to?' do
    context "when ENV var is not present" do
      it "responds to :foo" do
        expect(subject).to respond_to(:foo)
      end

      it "does not respond to :foobar" do
        expect(subject).to_not respond_to(:foobar)
      end
    end
  end
end

__END__

s = SettingsBag.new(hsh)
s.foo # => 1
s.bar # => { baz: 2 }
s.qux # => nil
ENV["CALAGATOR_WAT"] = "wat?"
s.wat # => "wat?"
ENV["CALAGATOR_FOO"] = 42
s.foo # => 42

# hash has the key/value pair
# hash doesn't, and the ENV does
  # prefix?!
