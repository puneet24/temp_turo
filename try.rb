# Ruby Script
# Fetching Car Listing data from turo.com
# Complete data after evry 1 month

require 'mechanize'

@agent = Mechanize.new

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
					img_str = car_page.parser.css(sel)[0]["style"].to_s
					puts img_str
					uploaded_page = imagehost_page.form_with(:name => "form1") do |form|
						url_field = form.field_with(:id => "upload")
						puts img_str.index('(')
						url_field.value = img_str[img_str.index('(').to_i+1..img_str.index(')').to_i-1]
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
				puts "*"*30
				puts city_url
				puts "owner :- #{owner}"
				puts "make_and_model :- #{make_and_model}"
				puts "year :- #{year}"
				puts "description :- #{description}"
				puts "price :- #{price}"
				puts "*"*30
				i = i+1
			end
		end
	end
	
	sleep(30*24*60*60)
end
