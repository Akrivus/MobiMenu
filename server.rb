require 'dotenv/load'
require 'sinatra'
require 'csv'
require 'uri'

Displays = []
class Display
  attr_reader :path, :aspect_ratio, :name, :angle, :filename, :pid
  def initialize(row)
    @path, @aspect_ratio, @angle, @name = row[0..3]
    image(row[4])
  end
  def image(filename)
    @filename = URI.unescape(filename)
    @angle = @angle.to_i
    @ratios = @aspect_ratio.split('x')
    @ratios.reverse! if @angle.odd?
    @ratio = @ratios.map { |r| r.to_f }.inject(:/)
    system("fbset -g #{(@aspect_ratio.split('x') * 2).join(' ')} 32 -fb /dev/#{@path}")
    system([
      "convert#{" -rotate #{@angle * 90}" if @angle > 0}",
      "-geometry x#{@aspect_ratio.split('x')[1]}",
      "-extent #{@aspect_ratio} -background black",
      "~/MobiMenu/public/images/#{@filename}",
      "bgra:/dev/#{@path}"
    ].join(' '))
    save
  end
  def width
    return height * @ratio
  end
  def height
    return 384.0
  end
  def from_params(name, filename)
    @name = name
    image(filename)
  end
  def to_a
    [@path, @aspect_ratio, @angle, @name, @filename]
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
  def self.refresh!
    Displays.each do |display|
      display.image(display.filename)
    end
  end
end

DisplaySheet = CSV.read('./display.csv')
DisplaySheet.each do |row|
  Displays << Display.new(row)
end

disable :logging
enable :sessions
set :session_secret, ENV['SECRET']
set :environment, :production
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

Display.refresh!