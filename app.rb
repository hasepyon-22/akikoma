require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require './models'

# require 'nokogiri'
require 'open-uri'
require 'csv'
require "pp"
require 'kconv'
require 'net/http'
# require 'pry'

require 'date'

# require 'dotenv'
# require 'cloudinary'


enable :sessions


def scrape_timetable
  # cookie_option = "SFS_Cookie=3674039446.56783.498810320.1422482656"

  login_uri = 'https://vu.sfc.keio.ac.jp/sfc-sfs/login.cgi'


  res = Net::HTTP.post_form(URI.parse(login_uri),{'u_login' => 't18659rh', 'u_pass' => 'Ryojun0209'})
  text = res['Set-Cookie']
  cookie_option = text.sub(/\;.*/, '')
  p cookie_option
  # アクセストークンを取得

  # #アクセストークを元にスクレイピング
  # doc = open("https://vu.sfc.keio.ac.jp/sfc-sfs/portal_s/s01.cgi?id=7de67f9858247eb6564463fcd189da2cd0fefe7d8fdd4660&type=s&mode=1&lang=ja", { 'Cookie' => cookie_option }).read.toutf8

  # doc = open("https://vu.sfc.keio.ac.jp/sfc-sfs/portal_s/s01.cgi?id=701802207c530dd2c4ceb72137b2506cc9f2954e5f848f38&type=s&mode=1&lang=ja", { 'Cookie' => cookie_option }).read.toutf8



  #スクレイプしたiframeをもとに時間割を読み込む
  html = open("https://vu.sfc.keio.ac.jp/sfc-sfs/sfs_class/student/view_timetable.cgi?id=701802207c530dd2c4ceb72137b2506cc9f2954e5f848f38&term=2019f&fix=1&lang=ja", { 'Cookie' => cookie_option }).read.toutf8

  tds = []
  parsed_html = Nokogiri::HTML.parse(html, nil, 'utf-8')
  td = parsed_html.css('td')
  td.each do |t|
    tds << t
  end
  p tds

end

helpers do
  def current_user
    User.find_by(id: session[:user])
  end

  def friended_users
    friendships = Friendship.where(user_id: current_user.id)
    friends = []
    friendships.each do |friendship|
      if Friendship.find_by(user_id: friendship.friend.id, friend_id: current_user.id)
        friends << friendship.friend
      end
    end
    friends
  end
end

before do
  Dotenv.load
  Cloudinary.config do |config|
    config.cloud_name = ENV['CLOUD_NAME']
    config.api_key = ENV['CLOUDINARY_API_KEY']
    config.api_secret = ENV['CLOUDINARY_API_SECRET']
  end

  if !current_user && request.path_info != "/signin" && request.path_info != "/signup"
    redirect '/signin'
  end
end




get '/register' do
  erb :register
end

post '/register' do
  if UsersLecture.where(user_id: current_user.id)
    users = UsersLecture.where(user_id: current_user.id)

    users.each do |user|
      user.lecture.destroy
    end


  end

  lectures = params[:timetable]
  lectures.each do |lecture|
    day = lecture.slice(0, 3)
    period = lecture.slice(3, 5).to_i
    jyugyou = Lecture.create(day: day, period: period)
    UsersLecture.create(lecture_id: jyugyou.id, user_id: current_user.id)
  end

  redirect '/'
end

get '/signup' do
  erb :signup


end

post '/signup' do
  img_url = ''
  if params[:file]
    img = params[:file]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
  end

  @user = User.create(name: params[:name], password: params[:password], password_confirmation: params[:password_confirmation], img: img_url)

  if @user.persisted?
    session[:user] = @user.id
    redirect '/register'

  end
end

get '/signin' do
  erb :signin
end

post '/signin' do
  user = User.find_by(name: params[:name])
  if user && user.authenticate(params[:password])
    session[:user] = user.id
    redirect '/'
  else
     redirect '/signin'
  end
end

get '/signout' do
  session[:user] = nil
  redirect '/signin'
end

get '/' do
  users = UsersLecture.where(user_id: current_user.id)

  weekday = ["mon", "tue", "wed", "thu", "fri"]

  users.each do |user|
    for num in 0..4
      if user.lecture.day == weekday[num]
        for i in 1..6
          if user.lecture.period == i
            timing = weekday[num] + i.to_s
            instance_variable_set("@#{timing}", user.lecture)

          end
        end
      end
    end

  end


  #時間に合わせて各コマの暇な人を検出
  current_time = Time.now.in_time_zone('Tokyo')
  current_day = current_time.wday

  year = current_time.year
  month = current_time.month
  day = current_time.day
  weekday = ["mon", "tue", "wed", "thu", "fri"]

  end_of_period1 = Time.new(year, month, day, 10, 55, 0, "+09:00")
  end_of_period2 = Time.new(year, month, day, 12, 40, 0, "+09:00")
  end_of_period3 = Time.new(year, month, day, 14, 30, 0, "+09:00")
  end_of_period4 = Time.new(year, month, day, 16, 15, 0, "+09:00")
  end_of_period5 = Time.new(year, month, day, 18, 00, 0, "+09:00")
  end_of_period6 = Time.new(year, month, day, 19, 45, 0, "+09:00")

  if current_time < end_of_period1
    @period = 1
  elsif current_time < end_of_period2
    @period = 2
  elsif current_time < end_of_period3
    @period = 3
  elsif current_time < end_of_period4
    @period = 4
  elsif current_time < end_of_period5
    @period = 5
  else
    @period = 6
  end

  @friends_free_now = []
  @friends_free_will = []
  friended_users.each do |friend|
    if !friend.lectures.find_by(day: weekday[current_day - 1], period: @period)
      @friends_free_now << friend
    end
  end

  friended_users.each do |friend|
    if !friend.lectures.find_by(day: weekday[current_day - 1], period: @period + 1)
      @friends_free_will << friend
    end
  end



  erb :index


end

get '/friends' do
  @friends = Friendship.where(user_id: current_user.id)

  erb :friends
end

get '/friends/:id' do
  users = UsersLecture.where(user_id: params[:id])

  weekday = ["mon", "tue", "wed", "thu", "fri"]

  users.each do |user|
    for num in 0..4
      if user.lecture.day == weekday[num]
        for i in 1..6
          if user.lecture.period == i
            timing = weekday[num] + i.to_s
            instance_variable_set("@#{timing}", user.lecture)

          end
        end
      end
    end

  end

  @user = User.find(params[:id])


  erb :user
end


get '/search' do
  @user = User.find_by(name: session[:result])
  erb :search
end

post '/search' do
  session[:result] = params[:name]
  redirect back
end

post '/add/:id' do
  if !Friendship.find_by(user_id: current_user.id, friend_id: params[:id])
    Friendship.create(user_id: current_user.id, friend_id: params[:id])
  end

  redirect back
end

get '/mypage' do
  users = UsersLecture.where(user_id: current_user.id)

  weekday = ["mon", "tue", "wed", "thu", "fri"]

  users.each do |user|
    for num in 0..4
      if user.lecture.day == weekday[num]
        for i in 1..6
          if user.lecture.period == i
            timing = weekday[num] + i.to_s
            instance_variable_set("@#{timing}", user.lecture)

          end
        end
      end
    end

  end

  erb :mypage
end