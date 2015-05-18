# coding: utf-8
require 'mechanize'
require 'kconv'

DOMAIN = 'https://p.eagate.573.jp'
PROPERTY_FILE_NAME = 'prop.txt'

class Music
	attr_accessor :mid, :name, :score, :combo, :rank

	def initialize(agent, elem)
		@name = elem.xpath("td[2]/a/text()")
		path = elem.xpath("td[2]/a/@href").text;
		score_bsc = get_score(elem.xpath("td[3]/text()")[0].text.strip)
		score_adv = get_score(elem.xpath("td[4]/text()")[0].text.strip.to_i)
		score_ext = get_score(elem.xpath("td[5]/text()")[0].text.strip.to_i)
		combo_bsc = elem.xpath("td[3]/div/@class").text.strip == 'fc1'
		combo_adv = elem.xpath("td[4]/div/@class").text.strip == 'fc1'
		combo_ext = elem.xpath("td[5]/div/@class").text.strip == 'fc1'

		@mid = path.match(/mid=(\d+)/)[1].to_i
		@score = [score_bsc, score_adv, score_ext]
		@combo = [combo_bsc, combo_adv, combo_ext]

		# TODO: read rank
	end

	def get_score(str)
		str == '-' ? 0 : str.to_i
	end

	def to_s
		"id:#{@mid} name:#{@name} score(BSC):#{score[0]} #{combo[0]} score(ADV):#{score[1]} #{combo[1]} score(EXT):#{score[2]} #{combo[2]}"
	end
end

def login(agent)
	account = IO.readlines(PROPERTY_FILE_NAME);
	id = account[0].strip
	pass = account[1].strip
	page = agent.get("#{DOMAIN}/gate/p/login.html");
	agent.page.encoding = 'Shift_JIS'
	form = page.forms[0]
	form.KID = "#{id}"
	form.pass = "#{pass}"
	agent.submit(form)
end

def get_results(agent)
	list = []
	1.upto(12) do |idx| # todo: retrieve number of pages automatically
		page = agent.get("#{DOMAIN}/game/jubeat/prop/p/playdata/music.html?sort=&page=#{idx}")
		get_results_page(agent, page, list)
	end
	return list
end

def get_results_page(agent, page, list)
	doc = Nokogiri::HTML(page.content.toutf8)
	doc.xpath("//table[@id='play_music_table']//tr[position() > 2]").each do |elem|
		list << Music.new(agent, elem);
	end
end


def main
	agent = Mechanize::new
	login(agent)
	music_list = get_results(agent)
	puts music_list
end


main

