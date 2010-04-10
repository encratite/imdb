require 'nil/file'
require 'nil/string'

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
	puts 'Reading'
	data = Nil.readFile target
	puts 'Done'
	if data == nil
		puts "Unable to read #{target}"
		return nil
	end
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

def extractMovies(movies, year, outputDirectory)
	puts "Processing year #{year}"
	puts 'Filtering'
	filteredMovies = movies.reject do |movie|
		movie.name[0] == '"' ||
		movie.rating < 7.5 ||
		movie.votes < 1000 ||
		movie.year != year ||
		movie.flag != nil
	end
	puts 'Sorting'
	sortedMovies = filteredMovies.sort
	puts 'Serialising'
	output = sortedMovies.map { |movie| movie.description }.join("\n")
	puts 'Writing'
	path = outputDirectory + year.to_s
	Nil.writeFile(path, output)
end

target = 'G:\IMDB\ratings.list'
outputDirectory = 'E:\Code\Ruby\imdb\data\\'
movies = processRatings target
puts "Loaded #{movies.length} movies"

(1990..2010).each { |year| extractMovies(movies, year, outputDirectory) }
