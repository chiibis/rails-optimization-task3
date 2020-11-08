class Playground

  FILENAME = 'small.json'

  def call
    puts "### Playground START", "  #{FILENAME}"

    trips_count = json_stream_read

    puts "  read #{trips_count} Trips"
    puts "  MEMORY USAGE: #{memory_usage_mb} MB"

    puts "### <- END"
  end

  def json_stream_read
    counter = 0
    file_stream = File.open(full_path, 'r')

    streamer = Json::Streamer.parser(file_io: file_stream)

    streamer.get(nesting_level: 1) do |object|
      counter += 1
      # puts "single trip #{object}", ""
    end

    counter
  end

  def memory_usage_mb
    usage_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    usage_mb
  end

  def full_path
    "fixtures/#{FILENAME}"
  end
end