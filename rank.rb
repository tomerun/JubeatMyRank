# coding: utf-8
require 'mechanize'
require 'kconv'

DOMAIN = 'https://p.eagate.573.jp'
PROPERTY_FILE_NAME = 'prop.txt'

def page_to_doc(page)
	Nokogiri::HTML(page.content.toutf8) # avoid encoding issue
end

Chart = Struct.new(:score, :fullcombo, :level, :rank, :play_count) do
	def to_s
		sprintf("LEVEL:%2d score:%7d%4s rank:%6d位 play:%2d回", level, score, fullcombo ? '(FC)' : '', rank, play_count)
	end
end

Music = Struct.new(:mid, :name, :charts) do
	def to_s
		"id:#{mid} name:#{name}\n  [BSC] #{charts[0]}\n  [ADV] #{charts[1]}\n  [EXT] #{charts[2]}" 
	end
end

def create_chart(agent, elem, fullcombo)  # elem = <div class="seq">
	rows = elem.xpath("descendant::tr")
	level = rows[0].xpath("td[2]/text()").text.match(/LEVEL : (\d+)/)[1].to_i
	play_count = rows[1].xpath("td[2]/text()").text.match(/(\d+)回/)[1].to_i
	score = rows[5].xpath("td[2]/text()").text.strip.to_i
	rank_match = rows[6].xpath("td[2]/text()").text.match(/(\d+)位/)
	rank = rank_match ? rank_match[1].to_i : 0
	Chart.new(score, fullcombo, level, rank, play_count)
end

def create_music(agent, elem)  # elem = <tr class="odd" or class="even">
	name = elem.xpath("td[2]/a/text()")
	path = elem.xpath("td[2]/a/@href").text;
	mid = path.match(/mid=(\d+)/)[1].to_i

	music_page = page_to_doc(agent.get(DOMAIN + path));
	chart_elems = music_page.xpath("//div[@id='seq_container']/div[@class='seq']")
	charts = (0..2).map do |i|
		combo = elem.xpath("td[#{i+3}]/div/@class").text.strip == 'fc1'
		create_chart(agent, chart_elems[i], combo)
	end
	Music.new(mid, name, charts)
end

def login(agent)
	account = IO.readlines(PROPERTY_FILE_NAME);
	id = account[0].strip
	pass = account[1].strip
	page = agent.get("#{DOMAIN}/gate/p/login.html");
	agent.page.encoding = 'Shift_JIS'
	form = page.forms[0]
	form.KID = id
	form.pass = pass
	agent.submit(form)
end

def get_results(agent)
	(1..12).flat_map do |idx| # TODO: retrieve total number of pages automatically
		puts "fetching page #{idx}..."
		page = agent.get("#{DOMAIN}/game/jubeat/prop/p/playdata/music.html?sort=&page=#{idx}")
		get_results_page(agent, page)
	end
end

def get_results_page(agent, page)
	doc = page_to_doc(page)
	doc.xpath("//table[@id='play_music_table']//tr[position() > 2]").map do |elem|
		sleep(0.5)
		create_music(agent, elem);
	end
end

def download_result
	agent = Mechanize::new
	login(agent)
	return get_results(agent)
end

def main
	puts download_result
end

main

