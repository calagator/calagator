require 'settings_reader'

describe SettingsReader do
  describe '.read' do
    let(:filename) { 'spec/fixtures/settings_reader.yml' }
    subject { described_class.read(filename) }

    it 'returns an object that responds to a key in a yaml file' do
      expect(subject).to respond_to :foo
    end

    it "renders ERB in the yaml file" do
      expect(subject.erb).to eq('5')
    end

    context 'when passed a defaults hash argument' do
      subject { described_class.read(filename, { bar: 4, foo: 5 }) }

      it 'returns an object that responds to a key in the defaults hash argument' do
        expect(subject).to respond_to :bar
      end

      it 'prefers the yaml value over the defaults value' do
        expect(subject.foo).to eq(1)
      end
    end
  end
end
