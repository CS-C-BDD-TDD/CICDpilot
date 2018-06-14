# This middleware captures any route that matches the route listed and returns.
# This will not hit the Database in any way and should be used purely as a health check.
class PingNoDb  
  OK_RESPONSE = [ 200, { 'Content-Type' => 'text/plain' }, ["Hello! The application is running - #{Time.now}".freeze] ]

  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'.freeze] == '/ping_no_db'.freeze
      RequestLogger.info("Ping no Database request made at #{Time.now}, URL: #{env["REQUEST_URI"]}")
      return OK_RESPONSE
    else
      @app.call(env)
    end
  end
end 