require "logger"
require "timeout"
require "lib/common"

require "lumberjack/client"

describe "logstash-forwarder gem" do
  include_context "Helpers"

  before :all do
    @host = Socket.gethostname
  end

  def startup
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    # Reset server for each test
    @client = Lumberjack::Client.new(
      :ssl_ca => @ssl_cert.path,
      :addresses => ["127.0.0.1"],
      :port => server_port(),
      :logger => logger,
    )
  end

  def shutdown
    @client.shutdown
  end

  it "should send and receive events" do
    startup

    # Allow 60 seconds
    Timeout::timeout(60) do
      5000.times do |i|
        @client.publish "message" => "gem line test #{i}", "host" => @host, "file" => "gemfile.log"
      end
    end

    # Receive and check
    i = 0
    receive_and_check(total: 5000) do |e|
      expect(e["message"]).to eq "gem line test #{i}"
      expect(e["host"]).to eq @host
      expect(e["file"]).to eq "gemfile.log"
      i += 1
    end

    shutdown
  end
end