require 'crawler_rocks'
require 'json'
require 'pry'

class ProvidenceUniversityCrawler

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year-1911
		@term = term
		@update_progress_proc = update_progress
		@after_each_proc = after_each

		@query_url = 'http://alcat.pu.edu.tw/2011courseAbstract/main.php?type=mutinew&lang=zh'
	end

	def courses
		@courses = []

		r = RestClient.get(@query_url)
		doc = Nokogiri::HTML(r)

		doc.css('select[name="opunit"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}.each do |dep_c, dep_n|

			r = RestClient.post(@query_url, {
				"ls_yearsem" => "1041",
				"selectno" => "",
				"weekday" => "",
				"section" => "",
				"cus_select" => "",
				"classattri" => "1",
				"subjname" => "",
				"teaname" => "",
				"opunit" => dep_c,
				"opclass" => "",
				"lessonlang" => "",
				"search" => "搜尋",
				"click_ok" => "Y",
				})
			doc = Nokogiri::HTML(r)

			doc.css('table[class="table_info"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
				data = tr.css('td').map{|td| td.text}

###!!!課程代碼重複是因為一個課程有多位教師(官方設定的)!!!
				course = {
					year: @year,
					term: @term,
					department: dep_n,        # 開課系所
					general_code: data[0],    # 選課代號
					degree: data[1],          # 班級
					required: data[2],        # 修別 (必選修)
					name: data[3],            # 課程名稱
					term_type: data[4],       # 學期別
					credits: data[5],         # 學分數
					lecturer: data[6],        # 授課教師
					day_location: data[7],    # 上課時間地點
					people_last: data[8],     # 目前餘額(人數)
					notes: data[9],           # 備註說明
					}

				@after_each_proc.call(course: course) if @after_each_proc

				@courses << course
		# binding.pry
			end
		end
		@courses
	end

end

# crawler = ProvidenceUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
