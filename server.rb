require 'dotenv/load'
require 'sinatra'
require 'csv'

Displays = []
class Display
  attr_reader :path, :aspect_ratio, :name, :filename
  def initialize(row)
    @path, @aspect_ratio, @name = row[0..2]
    image(row[3])
  end
  def image(filename)
    @ratio = @aspect_ratio.split(':').map { |ration| ration.to_f }.inject(:/)
    @filename = filename
    if Process.respond_to? :fork
      @proc.kill unless @proc.nil?
      @proc = fork do
        exec("fim -qwd /dev/#{@path} ./public/images/#{filename}")
      end unless filename.nil?
    end
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

enable :sessions
set :session_secret, ENV['SECRET']
set :server, 'thin'
set :host, '0.0.0.0'
set :port, 80
set :signed_in do |required|
  condition do
    redirect '/sign-in' unless session[:signed_in]
  end if required
end
def message
  return nil
end

get '/sign-out' do
  erb(:sign_out)
end
get '/sign-in' do
  erb(:sign_in)
end
post '/sign-in' do
  unless params[:password].eql? ENV['PASSWORD']
    erb(:sign_in, locals: { message: 'Incorrect password.' })
  else
    session[:signed_in] = true
    redirect '/'
  end
end
get '/', signed_in: true do
  erb(:dashboard)
end
get '/display/:path', signed_in: true do
  erb(:display, locals: { display: Display.find(params[:path]) })
end
post '/display/:path', signed_in: true do
  display = Display.find(params[:path])
  unless params[:image].nil?
    display.from_params(params[:name], params[:image][:filename])
    File.open("./public/images/#{params[:image][:filename]}", 'wb') do |file|
      File.open(params[:image][:tempfile].path, 'rb') do |temp|
        file.write(temp.read)
      end
    end
  else
    display.from_params(params[:name], nil)
  end
  redirect '/'
end