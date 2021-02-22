require 'nokogiri'
require 'open-uri'
require 'pry'
require 'set'

class Scraper

    TOPICS_URL = "https://medium.com/topics"
    BASE_URL = "https://medium.com"
    OUTPUT_FILE = './medium_data.txt'

    def self.scrape
        discovered_tags = Set.new([])
        File.read(OUTPUT_FILE).each_line do |line|
            tag = line.split(',')[0]
            discovered_tags.add(tag)
        end
        doc = URI.open(TOPICS_URL)
        html = Nokogiri::HTML(doc)
        links = html.css('.link')
        links.each do |link|
            tag = link.text
            next if discovered_tags.include?(tag)
            puts tag
            topic_url = link.attr('href')
            topic_doc = URI.open(topic_url)
            topic_html = Nokogiri::HTML(topic_doc)
            topic_links = topic_html.css('h3 a').to_a.filter do |a| 
                 a['rel'] == 'noopener' && a['href'][0] == '/' && a['href'].split('?').length == 2
             end
            seen_links = Set.new([])
            topic_links.each do |article_link|
                article_link = BASE_URL + article_link['href'].split('?')[0]
                begin
                    uri = URI.parse(article_link)
                rescue URI::InvalidURIError
                    uri = URI.parse(URI.escape(article_link))
                end
                next if seen_links.include?(uri)
                seen_links.add(uri)
                puts uri
                article_doc = URI.open(uri)
                article_html = Nokogiri::HTML(article_doc)
                begin
                    title = article_html.css('h1').first.text.gsub(',', '')
                rescue
                    begin
                        title = article_html.css('h2').first.text.gsub(',', '')
                    rescue
                        title = ''
                    end
                end
                text = article_html.css('p').text.gsub(',', '')
                next if text.length < 100
                File.write( OUTPUT_FILE, "#{tag},#{title},#{text}\n" , mode: 'a')
            end
        end

    end

end


Scraper.scrape
