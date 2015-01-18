require 'spec_helper'

describe TimeRangeHelper do
  let(:start_time) { DateTime.new(2008, 4, 1, 9, 00) }

  # Test all permutations of
  # - context-date: with vs without
  # - format: hcal vs html (tags stripped) vs text (tags stripped, '&ndash;' --> '-')
  tests = [
    # comment, end_time, results_without_context, results_with_context
    [ "start time only", nil,
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">Tuesday, April 1, 2008 at 9am</time>",
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">9am</time>"],
    [ "same day & am-pm", DateTime.new(2008, 4, 1, 11, 00),
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">Tuesday, April 1, 2008 from 9</time>&ndash;<time class=\"dtend dt-end\" title=\"2008-04-01T11:00:00\" datetime=\"2008-04-01T11:00:00\">11am</time>",
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">9</time>&ndash;<time class=\"dtend dt-end\" title=\"2008-04-01T11:00:00\" datetime=\"2008-04-01T11:00:00\">11am</time>" ],
    [ "same day, different am-pm", DateTime.new(2008, 4, 1, 13, 30),
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">Tuesday, April 1, 2008 from 9am</time>&ndash;<time class=\"dtend dt-end\" title=\"2008-04-01T13:30:00\" datetime=\"2008-04-01T13:30:00\">1:30pm</time>",
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">9am</time>&ndash;<time class=\"dtend dt-end\" title=\"2008-04-01T13:30:00\" datetime=\"2008-04-01T13:30:00\">1:30pm</time>" ],
    [ "different days", DateTime.new(2009, 4, 1, 13, 30),
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">Tuesday, April 1, 2008 at 9am</time> through <time class=\"dtend dt-end\" title=\"2009-04-01T13:30:00\" datetime=\"2009-04-01T13:30:00\">Wednesday, April 1, 2009 at 1:30pm</time>",
      "<time class=\"dtstart dt-start\" title=\"2008-04-01T09:00:00\" datetime=\"2008-04-01T09:00:00\">9am</time> through <time class=\"dtend dt-end\" title=\"2009-04-01T13:30:00\" datetime=\"2009-04-01T13:30:00\">Wednesday, April 1, 2009 at 1:30pm</time>" ]
  ]

  [nil, Date.new(2008, 4, 1)].each do |context_date|
    describe "with#{context_date.nil? ? "out" : ""} context date" do
      [:text, :hcal, :html].each do |format|
        tests.each do |label, end_time, expected_without_context, expected_with_context|
          expected = context_date ? expected_with_context : expected_without_context
          expected = expected.gsub(%r|\<[^\>]*\>|,'') if format != :hcal
          expected = expected.gsub('&ndash;', '-') if format == :text
          it "should format #{label} in #{format} format as '#{expected}'" do
            actual = helper.normalize_time(start_time, end_time, format: format, context: context_date)
            expect(actual).to eq expected
          end
        end
      end
    end
  end

  describe "with objects" do
    it "should format from objects that respond to just start_time" do
      event = Event.new(:start_time => Time.parse('2008-04-01 13:30'))
      actual = helper.normalize_time(event, format: :text)
      expect(actual).to eq "Tuesday, April 1, 2008 at 1:30pm"
    end

    it "should format from objects that respond to both start_time and end_time" do
      event = Event.new(:start_time => Time.parse('2008-04-01 13:30'),
                        :end_time => Time.parse('2008-04-01 15:30'))
      actual = helper.normalize_time(event, format: :text)
      expect(actual).to eq "Tuesday, April 1, 2008 from 1:30-3:30pm"
    end
  end
end
