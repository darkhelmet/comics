class Downloader
  include MonitorMixin
  include LolConcurrency::Future

  attr_reader :cache

  def initialize(cache)
    super()
    @cache = cache
  end

  def get(url)
    cache.fetch(url) { RestClient.get(url) }
  end

  def get_and_parse(url)
    Nokogiri::HTML(get(url))
  end
end
