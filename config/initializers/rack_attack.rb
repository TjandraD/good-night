Rack::Attack.throttle(
  "requests by IP",
  limit: GoodNight::Application::RateLimit::NUMBER,
  period: GoodNight::Application::RateLimit::PERIOD) do |request|
  request.ip
end

Rack::Attack.throttled_responder = lambda do |request|
  match_data  = request.env["rack.attack.match_data"]
  now         = match_data[:epoch_time]

  headers = {
    "RateLimit-Limit" => match_data[:limit].to_s,
    "RateLimit-Remaining" => "0",
    "RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s
  }

  [ 429, headers, [ "Request Throttled\n" ] ]
end

Rack::Attack.throttled_response_retry_after_header = true
