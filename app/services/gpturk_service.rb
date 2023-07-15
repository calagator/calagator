module GpturkService
  require 'rest-client'
  require 'json'

  def self.get_spam_label(text)
    url = "https://gpturk.cognitivesurpl.us/api/tasks/#{ENV["GPTURK_SPAM_MODEL_ID"]}/inferences"
    headers = { 'Content-Type' => 'application/json' }
    payload = { api_key: ENV["GPTURK_API_KEY"], text: text }.to_json
    response = RestClient.post(url, payload, headers)
    JSON.parse(response.body)["label"]["parsed_label"].to_i
  end
end