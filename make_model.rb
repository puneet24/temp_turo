require 'mechanize'
require 'elasticsearch'
require 'rest-client'

max_limit_rows = 50000

@make_and_model = Hash.new

@agent = Mechanize.new

imagehost_page = @agent.get("http://postimage.org/index.php?um=web")

client = Elasticsearch::Client.new 

res = client.search index: 'dev_car_luxury', type:'vehicles', body: {from: 0,query: {match_all: {}},size: max_limit_rows}

res["hits"]["hits"].each do |r|
	q_res = client.search index: 'dev_car_luxury', type: 'all_cars', body: {query: {match_phrase: {mapped_id: r["_id"]}}}
	#puts r["_source"]["make_and_model"]
	if r["_source"]["make_and_model"].nil?
		next
	end
	puts r["_source"]["make_and_model"]
	if @make_and_model[r["_source"]["make_and_model"]].nil?
		@make_and_model[r["_source"]["make_and_model"]] = 1
	else
		@make_and_model[r["_source"]["make_and_model"]] += 1
	end
end

puts @make_and_model.keys