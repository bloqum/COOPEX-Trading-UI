require 'uri'

class MarketsController < ApplicationController
  def show
    attempts_left ||= 3
    puts market_variables_url
    # market_variables_url = 'http://ec2-54-202-248-61.us-west-2.compute.amazonaws.com/markets/11.json'
    market_variables_url = 'http://ec2-34-213-160-216.us-west-2.compute.amazonaws.com/markets/btcltc.json'
    response = Faraday.get(market_variables_url, params.slice(:lang), 'Cookie' => request.headers['HTTP_COOKIE'])
    if response.status.to_i % 100 == 4
      head response.status
    else
      response.assert_success!
      @data = JSON.load(response.body).deep_symbolize_keys
    end
  rescue Faraday::Error::TimeoutError => e
    (attempts_left -= 1) > 0 ? retry : raise
  end

private

  def fiat_ccy
    @data.fetch(:currencies).find { |ccy| ccy.fetch(:type) == 'fiat' }
  end
  helper_method :fiat_ccy

  def find_ccy(code)
    @data.fetch(:currencies).find { |ccy| ccy.fetch(:code) == code.to_s }
  end
  helper_method :find_ccy

  def market_variables_url
    url = URI.parse(ENV.fetch('PLATFORM_ROOT_URL'))
    url = URI.join(url, '/markets/')
    URI.join(url, params[:market_id] + '.json')
  end
end
