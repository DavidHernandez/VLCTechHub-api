require 'spec_helper'

describe VLCTechHub::API::V1::Routes do
  def app
    VLCTechHub::API::Boot
  end

  let(:request_time) { Time.now.utc }

  describe "GET /v1/events" do
    subject(:events) { JSON.parse(last_response.body)['events'] }

    it "returns a list of all next events" do
      get "/v1/events?category=next"
      expect(last_response).to be_ok
      expect(past_events).to be_empty
    end

    it "returns a list of past events" do
      get "/v1/events?category=recent"
      expect(last_response).to be_ok
      expect(future_events).to be_empty
    end

    it "returns a list of events for that year and month" do
      get "/v1/events?year=2016&month=02"
      expect(last_response).to be_ok
      expect(events_for_year_month(2016,02)).not_to be_empty
    end

    it "returns not found if year or month are bad formatted" do
      get "/v1/events?year=20140&month=01"
      expect(last_response).to be_bad_request
      get "/v1/events?year=2014&month=001"
      expect(last_response).to be_bad_request
    end

  end

  describe "POST /v1/events" do
    subject(:event) { JSON.parse(last_response.body)['event'] }

    it "creates an event" do
      data = {
          title: 'Title',
          description: 'Description',
          link: 'Link',
          hashtag: 'hashtag',
          date: '20010101T12:00:00Z'
      }

      post "/v1/events", {event: data}
      expect(last_response).to be_created
      expect(event['id']).not_to be_nil
    end
  end

  describe "GET /v1/events/publish/" do
    context 'Event is not found' do
      it "returns 404 if not found" do
        get "/v1/events/publish/not-found-id"
        expect(last_response).to be_not_found
      end
    end

    context 'Event is found' do
      before do
        Grape::Endpoint.before_each do |endpoint|
          event = { 'date' => DateTime.now }
          repo = double(:events, publish: true, find_by_uuid: event)
          allow(endpoint).to receive(:events).and_return(repo)
        end
      end

      after{ Grape::Endpoint.before_each nil }

      it "tweets and sends a mail about it" do
        mailer = class_double('VLCTechHub::Event::Mailer').
          as_stubbed_const
        expect(mailer).to receive(:broadcast)

        twitter = class_double("VLCTechHub::Event::Twitter").
          as_stubbed_const
        expect(twitter).to receive(:tweet)

        get "/v1/events/publish/found-id"
        expect(last_response).to be_ok
      end
    end
  end

  describe "GET /v1/events/:slug" do
    subject(:event) { JSON.parse(last_response.body)['event'] }

    let(:created_event) do
      data = {
          title: 'Title',
          description: 'Description',
          link: 'Link',
          hashtag: 'hashtag',
          date: '20010101T12:00:00Z'
      }

      post "/v1/events", {event: data}
      event
    end

    it "returns the event" do
      get "/v1/events/#{created_event['slug']}"
      expect(last_response).to be_ok
      expect(event).to eq(created_event)
    end
  end

  def past_events
    events.select { |e| past_event? e }
  end

  def future_events
    events.select { |e| future_event? e }
  end

  def events_for_year_month year, month
    current_month = DateTime.new(year, month)
    events.select { |e| current_month? e, current_month }
  end

  def past_event? event
    event['date'] < request_time
  end

  def future_event? event
    event['date'] >= request_time
  end

  def current_month? event, current_month
    event['date'] >= current_month or event['date'] < current_month.next_month
  end
end
