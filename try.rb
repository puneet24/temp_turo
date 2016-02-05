# Ruby Script
# Fetching Car Listing data from turo.com
# Complete data after evry 1 month

require 'mechanize'
require 'mysql'

@agent = Mechanize.new

@con = Mysql.new 'localhost', 'luxex_wp', 'MRY*o*<L', 'luxex_wp'

while true do 
	
	imagehost_page = @agent.get("http://postimage.org/index.php?um=web")

	states_page = @agent.get("https://turo.com/all-cities/")

	if states_page.nil?
		puts "Connection Failed."
		exit
	else
		puts "Connection established."
	end

	state_set = states_page.parser.css("div.state-name")

	@all_states = Hash.new

	state_set.each do |state|
		@all_states[state.css("a")[0]["href"]] = []
	end



	@all_states.each do |key,value|
		city_page = @agent.get("https://turo.com/"+key)
		city_page.parser.css(".search-links.container").search("p").each do |city|
			@all_states[key] << city.search("a")[0]["href"]
		end
	end

	@all_states.each do |key,value|
		value.each do |city_url|
			car_listing_page = @agent.get("https://turo.com/"+city_url)
			count_of_vehicles = car_listing_page.parser.css(".js-carousel.carousel")[0]["data-item-count"]
			i = 0
			while i < count_of_vehicles.to_i do
				sel = 'div[data-item-index="' + i.to_s + '"]'
				vehicle_url = car_listing_page.parser.css(sel).search("a")[0]["href"]
				car_page = @agent.get("https://turo.com/" + vehicle_url)
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
				make_and_model = car_page.parser.css(".vehicleModelAndOwner-make-model").text.strip
				year = car_page.parser.css(".vehicleModelAndOwner-year").text.strip
				description = car_page.parser.css(".grid-item.grid-item--10.u-breakWord").text.strip
				price = car_page.parser.css(".vehicleListingSummary-dollars.vehicleListingSummary-dollars--sidebar.js-vehicleListingDailyAverage").text.strip
				#puts "*"*30
				city_obj = city_url[city_url.rindex("/").to_i+1..city_url.length]
				#puts "city :- " + city_obj
				state_obj = key[key.rindex('/').to_i+1..key.length]
				# puts "state :- #{state_obj}"
				# puts "owner :- #{owner}"
				# puts "make_and_model :- #{make_and_model}"
				# puts "year :- #{year}"
				# puts "description :- #{description}"
				# puts "price :- #{price}"
				# puts "*"*30
				
				id_fetch_query = 'SELECT id from wp_data where state = "' + state_obj.to_s + '" and city = "' + city_obj.to_s + '" and owner_name = "' + owner.to_s + '" and make_and_model = "' + make_and_model.to_s + '"'
				h = @con.query(id_fetch_query).fetch_row
				if h.nil?
					puts "insert"
					insert_form = 'INSERT INTO wp_data(state,city,owner_name,make_and_model,price,model_year,description) values("' + state_obj.to_s + '","' + city_obj.to_s + '","' + owner.to_s + '","' + make_and_model.to_s + '",' + price.to_s +  ',' + year.to_s + ',"' + description.to_s.gsub!("'","''") + '")'
					@con.query(insert_form)
					h = @con.query(id_fetch_query).fetch_row
				else
					puts "update"
					update_form = 'UPDATE wp_data set state = "' + state_obj.to_s + '", city = "' + city_obj.to_s + '", make_and_model = "' + make_and_model.to_s + '", price = ' + price.to_s + ', model_year = "' + year .to_s+ '", description = "' + description.to_s.gsub!("'","''") + '" where id = ' + h[0].to_s
					@con.query(update_form)
				end
				puts h
				image_urls.each do |objs|
					query_form = 'INSERT INTO wp_data_links(wp_data_id,img_path,url_path) values(' + h[0].to_s + ',"' + objs['img_path'].to_s + '","' + objs['url_path'].to_s + '")'
					@con.query(query_form)
				end
				i = i+1
			end
		end
	end
	
	sleep(30*24*60*60)
end
