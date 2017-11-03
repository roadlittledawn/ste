require 'multi_json'
module Sinatra
  module Auth
    API_KEY = ENV['API_KEY']
    def verify
      verified = (env['HTTP_X_API_KEY'] == API_KEY)
      halt 401, MultiJson.dump(message: 'not authorized') unless verified
    end
  end
  helpers Auth
end
