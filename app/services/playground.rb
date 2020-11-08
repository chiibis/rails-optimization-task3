class Playground

  FILENAME = 'small.json'   # 1000 trips
  # FILENAME = 'medium.json'  # 10000 trips
  # FILENAME = 'large.json'   # 100000 trips

  def call
    puts "### Playground START", ""

    trips_count = 0

    time = Benchmark.realtime do
      trips_count = json_stream_read
    end

    puts "filename      : #{FILENAME}"
    puts "trips count   : #{trips_count}"
    puts "processed in  : #{time.round(1)} seconds "
    puts "memory used   : #{memory_usage_mb} MB"

    puts "", "### <- END"
  end

  def json_stream_read
    counter = 0
    file_stream = File.open(full_path, 'r')

    streamer = Json::Streamer.parser(file_io: file_stream)

    streamer.get(nesting_level: 1, symbolize_keys: true) do |trip|
      counter += 1
      puts "single trip #{trip}", "" if counter <= 3
    end

    counter
  end

  def memory_usage_mb
    usage_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    usage_mb
  end

  def progress_bar
    trips_count = 1000
    progress_bar = ProgressBar.new(TRIPS_COUNT)
    progress_bar.increment!
  end

  def full_path
    "fixtures/#{FILENAME}"
  end
end