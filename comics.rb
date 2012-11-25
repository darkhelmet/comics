require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'downloader'

configure do
  disable :lock
  set :cache, ActiveSupport::Cache::DalliStore.new(expires_in: 1.day)
  set :stupid_prefixes, %w(atom10 feedburner)
end

helpers do
  def with_rss(url)
    settings.cache.fetch(url) do
      resp = RestClient.get(url)
      doc = Nokogiri::XML(resp)
      yield(doc)
      doc.to_s
    end
  end

  def remove_unless_title_match(doc, re)
    doc.search('item title').each do |title|
      title.parent.remove unless title.text.match(re)
    end
  end

  def with_each_link_and_page(doc)
    links = doc.search('item link')
    downloader_pool = Downloader.pool(size: links.count, args: [settings.cache])
    map = links.reduce({}) do |map, link|
      map.merge!(link => downloader_pool.future.get_and_parse(link.text))
    end

    links.each do |link|
      yield(link, map[link].value)
    end
  end

  def replace_description_with(doc, link, str)
    cdata = Nokogiri::XML::CDATA.new(doc, str)
    desc = link.parent.at('description')
    desc.children.each(&:remove)
    desc.add_child(cdata)
  end

  def stupid_feedburner(node)
    if node.namespace && settings.stupid_prefixes.include?(node.namespace.prefix)
      node.remove
      return
    else
      node.children.each { |child| stupid_feedburner(child) }
    end
  end
end

get '/' do
  'Hello, World!'
end

delete '/' do
  settings.cache.clear
  'ok'
end

get '/explosm' do
  content_type :rss
  with_rss('http://feeds.feedburner.com/Explosm') do |doc|
    stupid_feedburner(doc.root)
    remove_unless_title_match(doc, /\d{2}\.\d{2}\.\d{4}/)
    doc.at('channel link').remove
    with_each_link_and_page(doc) do |link, page|
      img = page.at('img:first[alt="Cyanide and Happiness, a daily webcomic"]')
      replace_description_with(doc, link, img.to_s)
    end
  end
end

get '/cad' do
  content_type :rss
  with_rss('http://www.cad-comic.com/rss/rss.xml') do |doc|
    remove_unless_title_match(doc, /^Ctrl/)
    with_each_link_and_page(doc) do |link, page|
      img = page.at('#content > img:first')
      replace_description_with(doc, link, img.to_s)
    end
  end
end
