require 'logger'

Downloader = Struct.new(:cache, :log)
  include MonitorMixin
  include LolConcurrency::Future

  def initialize(cache)
    super(cache, Logger.new(STDOUT))
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
