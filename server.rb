require 'dotenv/load'
require 'securerandom'
require 'sinatra'
require 'csv'
require 'uri'

Displays = []
class Display
  attr_reader :path, :resolution, :name, :rotation, :filename, :pid
  def initialize(row)
    @path, @resolution, @rotation, @name = row[0..3]
    image(row[4])
  end
  def image(filename)
    @filename = URI.unescape(filename) unless filename.nil?
    @rotation = @rotation.to_i
    @ratios = @resolution.split('x')
    @ratios.reverse! if [90, 270].include? @rotation
    @ratio = @ratios.map { |r| r.to_f }.inject(:/)
    system([
      "convert#{" -rotate #{@rotation}" if @rotation > 0}",
      "-geometry #{@resolution.split('x')[0]}x",
      "-extent #{@resolution} -background black -gravity center",
      "~/MobiMenu/public/images/#{@filename}",
      "bgra:/dev/#{@path}"
    ].join(' '))
  end
  def width
    return height * @ratio
  end
  def height
    return 384.0
  end
  def from_params(resolution, rotation, name, filename)
    @resolution = resolution
    @rotation = rotation.to_i
    @name = name
    image(filename)
  end
  def to_a
    [@path, @resolution, @rotation, @name, @filename]
  end
  def save
    CSV.open('display.csv', 'wb') do |csv|
      csv << DisplaySheet[0]
      DisplaySheet[1..-1].each do |row|
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
  def self.refresh!
    Displays.each do |display|
      display.image(display.filename)
    end
  end
end

DisplaySheet = CSV.read('./display.csv')
DisplaySheet[1..-1].each do |row|
  Displays << Display.new(row)
end

disable :logging
enable :sessions
set :session_secret, ENV['SECRET']
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
    image = SecureRandom.hex
    File.open("./public/images/#{image}", 'wb') do |file|
      File.open(params[:image][:tempfile].path, 'rb') do |temp|
        file.write(temp.read)
      end
    end
    display.from_params(params[:resolution], params[:rotation], params[:name], image)
  else
    display.from_params(params[:resolution], params[:rotation], params[:name], nil)
  end
  save
  redirect '/'
end

Display.refresh!
