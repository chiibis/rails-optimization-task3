class Playground

  FILENAME = 'small.json'   # 1000 trips
  # FILENAME = 'medium.json'  # 10000 trips
  # FILENAME = 'large.json'   # 100000 trips

  def call
    puts "### Playground START", ""

    trips_count = 0

    @services_cache = {}
    @services_arr = []

    @cities_cache = {}
    @cities_arr = []

    clear_db

    time = Benchmark.realtime do
      trips_count = json_stream_read
    end

    puts "filename      : #{FILENAME}"
    puts "trips count   : #{trips_count}"
    puts "processed in  : #{time.round(1)} seconds "
    puts "memory used   : #{memory_usage_mb} MB"

    puts "", "### <- END"
  end

  def clear_db
    City.delete_all
    Bus.delete_all
    Service.delete_all
    Trip.delete_all

    ActiveRecord::Base.connection.execute('delete from buses_services;')
  end

  def create_single_trip(trip)
    from = City.find_or_create_by(name: trip['from'])
    to = City.find_or_create_by(name: trip['to'])

    services = []

    trip['bus']['services'].each do |service|
      s = Service.find_or_create_by(name: service)
      services << s
    end

    bus = Bus.find_or_create_by(number: trip['bus']['number'])
    bus.update(model: trip['bus']['model'], services: services)

    trip_params = {
      from: from,
      to: to,
      bus: bus,
      start_time: trip['start_time'],
      duration_minutes: trip['duration_minutes'],
      price_cents: trip['price_cents']
    }

    Trip.new(trip_params)
  end

  def cached_service(service_name)
    service = @services_cache[service_name]

    unless service.present?
      service = Service.new(name: service_name)
      @services_cache[service_name] = service
      @services_arr << service
    end

    service
  end

  def cached_city(city_name)
    city = @cities_cache[city_name]

    unless city.present?
      city = City.new(name: city_name)
      @cities_cache[city_name] = city
      @cities_arr << city
    end

    city
  end

  def json_stream_read
    counter = 0
    file_stream = File.open(full_path, 'r')

    streamer = Json::Streamer.parser(file_io: file_stream)

    trips = []
    buses = []

    streamer.get(nesting_level: 1, symbolize_keys: false) do |trip|
      counter += 1
      next if counter > 1

      from = cached_city(trip['from'])
      to = cached_city(trip['to'])

      bus_services = []
      bus_node = trip['bus']

      bus_node['services'].each do |service|
        s = cached_service(service)
        bus_services << s
      end

      # bus_key = bus_node['model'] + bus_node['number']
      bus_params = {
        number: bus_node['number'],
        model: bus_node['model'],
        services: bus_services
      }

      bus = Bus.new(bus_params)
   
      trip_params = {
        from: from,
        to: to,
        bus: bus,
        start_time: trip['start_time'],
        duration_minutes: trip['duration_minutes'],
        price_cents: trip['price_cents']
      }

      trips << Trip.new(trip_params)
      buses << bus

    end

    City.import(@cities_arr)
    Service.import(@services_arr)
    Bus.import buses, recursive: true
    Trip.import(trips)

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