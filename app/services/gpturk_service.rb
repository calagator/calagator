module GpturkService
  require 'rest-client'
  require 'json'

  def self.is_this_spam?(text)
    self.get_spam_label(text) == 0
  end

  def self.get_spam_label(text)
    url = "https://gpturk.cognitivesurpl.us/api/tasks/#{ENV["GPTURK_SPAM_MODEL_ID"]}/inferences"
    headers = { 'Content-Type' => 'application/json' }
    payload = { api_key: ENV["GPTURK_API_KEY"], text: text }.to_json

    begin
      response = RestClient::Request.execute(
        method: :post,
        url: url,
        payload: payload,
        headers: headers,
        timeout: 5,       # Maximum time to get a response
        open_timeout: 5   # Maximum time to establish a connection
      )
      JSON.parse(response.body)["label"]["parsed_label"].to_i
    rescue RestClient::ExceptionWithResponse, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, SocketError
      return 1 # Failsafe to bypass any spam filtering if API unavailable
    end
  end
end