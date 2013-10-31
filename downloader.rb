require 'logger'

class Downloader
  include MonitorMixin
  include LolConcurrency::Future

  attr_reader :cache, :log

  def initialize(cache)
    super()
    @cache = cache
    @log = Logger.new(STDOUT)
  end

  def get(url)
    cache.fetch(url) do
      log.info("downloading #{url}")
      RestClient.get(url)
    end
  end

  def get_and_parse(url)
    Nokogiri::HTML(get(url))
  end
end
