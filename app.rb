require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require './models'

require 'nokogiri'
require 'open-uri'
require 'csv'
require "pp"
require 'kconv'
require 'net/http'
require 'pry'

require 'date'


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
end

before do
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
  @user = User.create(name:params[:name], password:params[:password], password_confirmation:params[:password_confirmation])

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


  @friends = Friendship.where(user_id: current_user.id)




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