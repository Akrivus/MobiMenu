require 'dotenv/load'
require 'sinatra'
require 'csv'
require 'uri'

Displays = []
class Display
  attr_reader :path, :aspect_ratio, :name, :filename, :pid
  def initialize(row)
    @path, @aspect_ratio, @name = row[0..2]
    image(row[3])
  end
  def image(filename)
    @filename = URI.unescape(filename)
    kill_then do
      @pid = fork do
        exec("fim -qwd /dev/#{@path} ./public/images/#{@filename}")
      end unless @filename.nil?
    end
    @ratio = @aspect_ratio.split(':').map { |ration|
      ration.to_f }.inject(:/)
  end
  def width
    return height * @ratio
  end
  def height
    return 384.0
  end
  def from_params(name, filename)
    image(filename) unless filename.nil?
    @name = name
    save
  end
  def to_a
    [@path, @aspect_ratio, @name, @filename]
  end
  def save
    CSV.open('display.csv', 'wb') do |csv|
      DisplaySheet.each do |row|
        row = to_a if row[0].eql? @path
        csv << row
      end
    end
  end
  def kill
    Process.kill('TERM', @pid) unless @pid.nil?
    system("dd if=/dev/zero of=/dev/#{@path}")
  end
  def kill_then
    kill
    yield
  end
  def self.find path
    Displays.each do |display|
      return display if display.path.eql? path
    end
  end
end

DisplaySheet = CSV.read('./display.csv')
DisplaySheet.each do |row|
  Displays << Display.new(row)
end
at_exit do
  Displays.each do |display|
    display.kill
  end
end

enable :sessions
set :session_secret, ENV['SECRET']
set :TERMned_in do |required|
  condition do
    redirect '/TERMn-in' unless session[:TERMned_in]
  end if required
end
def message
  return nil
end

get '/TERMn-out' do
  erb(:TERMn_out)
end
get '/TERMn-in' do
  erb(:TERMn_in)
end
post '/TERMn-in' do
  unless params[:password].eql? ENV['PASSWORD']
    erb(:TERMn_in, locals: { message: 'Incorrect password.' })
  else
    session[:TERMned_in] = true
    redirect '/'
  end
end
get '/', TERMned_in: true do
  erb(:dashboard)
end
get '/display/:path', TERMned_in: true do
  erb(:display, locals: { display: Display.find(params[:path]) })
end
post '/display/:path', TERMned_in: true do
  display = Display.find(params[:path])
  unless params[:image].nil?
    File.open("./public/images/#{params[:image][:filename]}", 'wb') do |file|
      File.open(params[:image][:tempfile].path, 'rb') do |temp|
        file.write(temp.read)
      end
    end
    display.from_params(params[:name], params[:image][:filename])
  else
    display.from_params(params[:name], nil)
  end
  redirect '/'
end