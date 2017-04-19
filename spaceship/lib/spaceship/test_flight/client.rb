module Spaceship::TestFlight
  class Client < Spaceship::Client
    def self.hostname
      'https://itunesconnect.apple.com/testflight/v2/'
    end

    # Returns an array of all available build trains (not the builds they include)
    def get_build_trains(app_id: nil, platform: nil)
      platform ||= "ios"
      response = request(:get, "providers/#{team_id}/apps/#{app_id}/platforms/#{platform}/trains")
      handle_response(response)
    end

    def get_builds_for_train(app_id: nil, platform: nil, train_version: nil)
      platform ||= "ios"

      response = request(:get, "providers/#{team_id}/apps/#{app_id}/platforms/#{platform}/trains/#{train_version}/builds")
      handle_response(response)
    end

    def post_tester(app_id: nil, tester: nil)
      # First we need to add the tester to the app
      # It's ok if the tester already exists, we just have to do this... don't ask
      # This will enable testing for the tester for a given app, as just creating the tester on an account-level
      # is not enough to add the tester to a group. If this isn't done the next request would fail.
      # This is a bug we reported to the iTunes Connect team, as it also happens on the iTunes Connect UI on 18. April 2017
      url = "providers/#{team_id}/apps/#{app_id}/testers"
      response = request(:post) do |req|
        req.url url
        req.body = {
          "email" => tester.email,
          "firstName" => tester.last_name,
          "lastName" => tester.first_name
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end

    def put_test_to_group(app_id: nil, tester_id: nil, group_id: nil)
      # Then we can add the tester to the group that allows the app to test
      # This is easy enough, we already have all this data. We don't need any response from the previous request
      url = "providers/#{team_id}/apps/#{app_id}/groups/#{group_id}/testers/#{tester_id}"
      response = request(:put) do |req|
        req.url url
        req.body = {
          "groupId" => group_id,
          "testerId" => tester_id
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end

    # def remove_tester_from_group!(group: nil, tester: nil, app_id: nil)
    def delete_tester_from_group(group_id: nil, tester_id: nil, app_id: nil)
      url = "providers/#{team_id}/apps/#{app_id}/groups/#{group_id}/testers/#{tester_id}"
      response = request(:delete) do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end

    def get_build(app_id: nil, build_id: nil)
      response = request(:get, "providers/#{team_id}/apps/#{app_id}/builds/#{build_id}")
      handle_response(response)
    end

    def put_build(app_id: nil, build_id: nil, build: nil)
      response = request(:put) do |req|
        req.url "providers/#{team_id}/apps/#{app_id}/builds/#{build_id}"
        req.body = build.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end

    def post_for_review(app_id: nil, build_id: nil, build: nil)
      response = request(:post) do |req|
        req.url "providers/#{team_id}/apps/#{app_id}/builds/#{build_id}/review"
        req.body = build.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end


    def get_groups(app_id: nil)
      response = request(:get, "/testflight/v2/providers/#{team_id}/apps/#{app_id}/groups")
      handle_response(response)
    end

    def add_group_to_build(app_id: nil, group_id: nil, build_id: nil)
      body = {
        'groupId' => group_id,
        'buildId' => build_id
      }
      response = request(:put) do |req|
        req.url "providers/#{team_id}/apps/#{app_id}/groups/#{group_id}/builds/#{build_id}"
        req.body = body.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      handle_response(response)
    end

    def handle_response(response)
      if (200..300).include?(response.status) && response.body.empty?
        return
      end

      unless response.body.is_a?(Hash)
        raise UnexpectedResponse.new(response.body)
      end

      if error = response.body['error']
        raise UnexpectedResponse.new(error)
      end

      if data = response.body['data']
        return data
      end

      response.body
    end
  end
end
