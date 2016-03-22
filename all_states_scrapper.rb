require 'mechanize'
require 'elasticsearch'
require 'rest-client'

max_limit_rows = 5000

@agent = Mechanize.new

client = Elasticsearch::Client.new 

res = client.search index: 'dev_car_luxury', type:'vehicles', body: {from: 0,query: {match_all: {}},size: max_limit_rows}


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
	@all_states[state.text] = state.css("a")[0]["href"]
	index_res = client.index index: 'dev_car_luxury', type: 'all_states', body: { state: state.text, state_url: state.css("a")[0]["href"]}
	puts index_res
end

puts @all_states.inspect



	