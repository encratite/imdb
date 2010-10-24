require 'nil/file'
require 'nil/string'
require 'nil/http'

require 'search-engine/BingSearchEngine'

require 'www-library/SiteRenderer'
require 'www-library/HTMLWriter'

require_relative 'configuration'

class Movie
	attr_reader :name, :rating, :votes, :year, :flag
	
	def initialize(name, rating, votes, year, flag)
		@name = name
		@rating = rating
		@votes = votes
		@year = year
		@flag = flag
	end
	
	def <=>(other)
		return 0 if @rating == other.rating
		return @rating < other.rating ? 1 : -1
	end
	
	def description
		return "#{name} (#{year}); rating: #{rating}; votes: #{votes}"
	end
end

def processRatings(target)
	puts 'Reading the IMDB database file...'
	data = Nil.readFile target
	if data == nil
		puts "Unable to read #{target}"
		return nil
	end
	puts 'Done reading the IMDB database file'
	data = data.extract('MOVIE RATINGS REPORT', '-------')
	return nil if data == nil
	lines = data.split "\n"
	pattern = /^(.+) \((\d+)\)( \(([A-Z]+)\))?$/
	movies = []
	lines.each do |line|
		next if line.size < 39
		votes = line[16..24].strip
		next if !votes.isNumber
		votes = votes.to_i
		rating = line[27..29].strip
		next if !rating.isNumber
		rating = rating.to_f
		description = line[32..-1]
		match = pattern.match description
		next if match == nil
		name = match[1]
		year = match[2].to_i
		flag = match[4]
		movie = Movie.new(name, rating, votes, year, flag)
		movies << movie
	end
	return movies
end

def generateOutput(movies)
	searchEngine = BingSearchEngine.new
	writer = WWWLib::HTMLWriter.new
	writer.table do
		writer.tr do
			columns =
			[
				'Rank',
				'Name',
				'Year',
				'Rating',
				'Votes',
			]
			columns.each do |column|
				writer.th { column }
			end
		end
		rank = 1
		movies.each do |movie|
			target = "#{movie.name} #{movie.year} site:imdb.com"
			puts "Processing #{movie.name}"
			results = searchEngine.search(target)
			if results == nil || results.empty?
				puts "Unable to retrieve the IMDB URL of movie #{movie.name}"
				next
			end
			url = results.first.url
			writer.tr do
				writer.td { rank.to_s }
				writer.td do
					writer.a(href: url) { movie.name }
				end
				writer.td { movie.year.to_s }
				writer.td { movie.rating.to_s }
				writer.td { movie.votes.to_s }
			end
			rank += 1
		end
	end
	return writer.output
end

def extractMovies(movies, year, outputDirectory)
	puts "Processing year #{year}"
	puts 'Filtering'
	filteredMovies = movies.reject do |movie|
		movie.name[0] == '"' ||
		movie.rating < IMDBConfiguration::MinimumRating ||
		movie.votes < IMDBConfiguration::MinimumVotes ||
		movie.year != year ||
		movie.flag != nil
	end
	puts 'Sorting'
	sortedMovies = filteredMovies.sort
	renderer = WWWLib::SiteRenderer.new
	renderer.addStylesheet('../style/imdb.css')
	title = "Movies of the year #{year}"
	content = generateOutput sortedMovies
	output = renderer.get(title, content)
	fileName = "#{year}.html"
	outputPath = Nil.joinPaths(outputDirectory, fileName)
	Nil.writeFile(outputPath, output)
end

target = IMDBConfiguration::RatingsPath
outputDirectory = IMDBConfiguration::OutputDirectory
movies = processRatings target
puts "Loaded #{movies.length} movies"

(IMDBConfiguration::FirstYear..IMDBConfiguration::LastYear).each { |year| extractMovies(movies, year, outputDirectory) }
