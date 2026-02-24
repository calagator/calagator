# frozen_string_literal: true

require "rails_helper"

describe "Administrative suite is hidden behind an http basic auth wall", type: :request do
  [
    "/admin",
    "/events/duplicates",
    "/venues/duplicates"
  ].each do |path|
    it "unauthenticated users are denied access to #{path}" do
      get path
      expect(response).to have_http_status(:unauthorized)
    end

    it "authenticated users are permitted in #{path}" do
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials(
        Calagator.admin_username, Calagator.admin_password
      )
      get path, headers: {"HTTP_AUTHORIZATION" => credentials}
      expect(response).to have_http_status(:success)
    end
  end
end
