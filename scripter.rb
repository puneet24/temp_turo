require 'mechanize'
require 'mysql'
require 'elasticsearch'
require 'rest-client'

max_limit_rows = 5000

@agent = Mechanize.new

imagehost_page = @agent.get("http://postimage.org/index.php?um=web")

client = Elasticsearch::Client.new 

res = client.search index: 'dev_car_luxury', type:'vehicles', body: {from: 0,query: {match_all: {}},size: max_limit_rows}

res["hits"]["hits"].each do |r|
	puts r
	q_res = client.search index: 'dev_car_luxury', type: 'all_vehicles', body: {query: {match: {mapped_id: r["_id"]}}}
	puts "*"*60
	puts q_res["hits"]["total"]
	puts "*"*60
	if q_res["hits"]["total"].to_i == 0
		vehicle_url = r["_source"]["car_path"]
		puts r["_id"]
		car_page = @agent.get("https://turo.com" + vehicle_url)
		#Extracting car information
		image_urls = []
		count_of_images = car_page.parser.css(".js-carousel.carousel")[0]["data-item-count"]
		j = 0
		while j < count_of_images.to_i do
			sel = 'div[data-item-index="' + j.to_s + '"]'
			if j == 0
				img_str = car_page.parser.css(sel)[0]["style"].to_s
			else
				img_str = car_page.parser.css(sel)[0]["data-src"].to_s
			end
			uploaded_page = imagehost_page.form_with(:name => "form1") do |form|
				url_field = form.field_with(:id => "upload")
				if j == 0
					url_field.value = img_str[img_str.index('(').to_i+1..img_str.index(')').to_i-1]
				else
					url_field.value = img_str
				end
			end.submit
			str =  uploaded_page.parser.css("#code_2").text
			obj = {}
			obj['img_path'] = str[str.index("[img]").to_i+5..str.index("[/img]").to_i-1]
			obj['url_path'] = str[str.index("url=").to_i+4..str.index("/]").to_i-1]
			image_urls << obj
			j = j+1
		end
		puts image_urls.inspect
		owner = car_page.parser.css(".vehicleModelAndOwner-owner").text.strip
		vehicle_map = car_page.parser.css("#vehicle-map")
		lat = vehicle_map[0]["data-latitude"]
		lot = vehicle_map[0]["data-longitude"]
		owned_by = car_page.parser.css(".driverDetails-name.u-truncate > a.text--purple").text.strip
		puts owned_by
		features = car_page.parser.css('div.vehicleSectionTitle:contains("FEATURES") + div > ul > li').text.strip
		features = features.split("\n").join(",")
		puts features
		image_urls = image_urls.join(",")
		puts image_urls
		make_and_model = car_page.parser.css(".vehicleModelAndOwner-make-model").text.strip
		year = car_page.parser.css(".vehicleModelAndOwner-year").text.strip
		description = car_page.parser.css(".grid-item.grid-item--10.u-breakWord").text.strip
		price = car_page.parser.css(".vehicleListingSummary-dollars.vehicleListingSummary-dollars--sidebar.js-vehicleListingDailyAverage").text.strip
		#puts "*"*30
		city_obj = r["_source"]["city"][r["_source"]["city"].to_s.rindex("/").to_i+1..r["_source"]["city"].length]
		puts "city :- " + city_obj
		state_obj = r["_source"]["state"][r["_source"]["state"].to_s.rindex('/').to_i+1..r["_source"]["state"].length]
		puts "state :- #{state_obj}"
		puts "owner :- #{owner}"
		puts "make_and_model :- #{make_and_model}"
		puts "year :- #{year}"
		puts "description :- #{description}"
		puts "price :- #{price}"
		puts "*"*30
		obj = '""'
		index_res = client.index index: 'dev_car_luxury', type: 'all_vehicles', body: { owner: owner,make_and_model: make_and_model,year: year,description: description,price: price,owned_by: owned_by, lat: lat,long: lot,image_urls: image_urls,features: features,city: r["_source"]["city"],state:r["_source"]["state"], vehicle_url: vehicle_url,mapped_id: r["_id"]}
		puts index_res
	end
end