require 'pp'
require 'json'

unless ARGV.size == 1
  $stderr.puts "Usage: ruby #{__FILE__} runs.json"
  raise "Invalid Arguments"
end

def load_json(runs_json)
  JSON.load( File.open(runs_json) )
end

def print_profile(runs)
  min_start_at = runs.map {|run| run["startAt"] }.min
  max_finish_at = runs.map {|run| run["finishAt"] }.max
  num_places = runs.uniq {|run| run["placeId"] }.size
  duration = runs.inject(0) {|sum,run| sum + (run["finishAt"] - run["startAt"]) }
  filling_rate = duration.to_f / ((max_finish_at - min_start_at) * num_places)

  $stdout.puts "Num Consumer Places : #{num_places}"
  $stdout.puts "Elapsed Time        : #{max_finish_at - min_start_at} ms"
  $stdout.puts "Total Job Duration  : #{duration} ms"
  $stdout.puts "Total Num Runs      : #{runs.size}"
  $stdout.puts "Job Filling Rate    : #{sprintf("%.1f", filling_rate*100)} %"
end

runs = load_json(ARGV[0])
print_profile( runs )

