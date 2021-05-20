require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions 


include Model

# Förhindrar att man ska kunna gå in på sidor utan tillstånd/inlogg
#  
#  @session [integer] sessionid, userid of current user 
#  [string] content, Message for user to show them that a login is required
#  [string] returnto, modular path the user is being directed to after error
#  [string] linktext, message for user 
# end
before do
  sessionid = session[:id].to_i
  if  request.path_info != '/' && session[:id] == nil && request.path_info != '/error' && request.path_info != '/showlogin'
    content = "You have to login before you do that!"
      returnto = "/showlogin"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  end
  
end


# directs you to register page
get('/')  do
  if session[:loggedin] == true
    content = "you are logged in already, logout first first to change account"
    returnto = "/posts/index"
    linktext = "Go back"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else
    slim(:register)
  end
end 

# shows the login page
get('/showlogin')  do
  if session[:loggedin] == true
    content = "you are logged in already, logout first first to change account"
    returnto = "/posts/index"
    linktext = "Go back"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else
    slim(:login)
  end

end 



# Login and display posts page
#
# @param [String] name, the username of the user
# @param [String] password, the non-decrypted password of the user
# @see model#verify_user
post('/login') do 
  name = params[:username]
  password = params[:password]
  result = verify_user(name, password)
  if result[0] == true 
      session[:id] = result[1] #användarid:et returneras med från en array i verify_user funktionen i model.rb.
      # session[:usertype] = result[2] #Användarens usertype
      session[:name] = name
      session[:loggedin] = true
      redirect('/posts/index')
  else
      content = "You have either entered the wrong password or used an invalid username."
      returnto = "/showlogin"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  end
end


# the route is fist of all formatting the posts data which results in the variabel formatted, The formatted data is the used to display the posts.
# 1 gets all the data from posts and also inner joins correlation tables.
# 2 The code then creates a better and more usable hash which in turn is being used to create the posts on the site 
#
# @session [integer] sessionid, id of curret user
# @see model#verify_user
# @see model#userdata
get('/posts/index') do
  sessionid = session[:id].to_i

  if sessionid == 0
    content = "You have to login before you do that!"
    returnto = "/showlogin"
    linktext = "Try again"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else

    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true 
    tester = db.execute("SELECT *

    FROM posts
    INNER JOIN exercises_post_correlation ON posts.id = exercises_post_correlation.post_id
    INNER JOIN exercises ON exercises_post_correlation.exercise_id = exercises.id
    INNER JOIN user_post_correlation ON posts.id = user_post_correlation.post_id
    ")

    p tester


    formatted = []
    x = ""

    tester.each do |t| 
      exercises = []
      reps = []
      sets = []
      time = []


      x = t['post_name']

      tester.each do |t| 

        if t['post_name'] == x
          exercises << t['name']
        end

        if t['post_name'] == x
          reps << t['reps']
        end

        if t['post_name'] == x
          sets << t['sets']
        end

        if t['post_name'] == x
          time << t['time']
        end
        
      end

      formatted << {post_name: t['post_name'],date: t['date'], catagory: t['catagory'],text: t['text'],post_id: t['post_id'],exercises: exercises, reps: reps, time: time, sets: sets,user_id: t['user_id']}

    end

    userdata = userdata(sessionid)
    p userdata
    p "#{userdata['privilege']}"

    formatted.uniq!
    slim(:"posts/index",locals:{result: formatted, sessionid: sessionid, userdata: userdata})
  end
end

# Create new user 
#
# @session [integer] sessionid, id of curret user
# @see model#exercises
# @see model#formatted
get('/posts/new') do
  sessionid = session[:id].to_i 
  if sessionid == 0
    content = "You have to login before you do that!"
    returnto = "/showlogin"
    linktext = "Try again"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else
    formatted = formatted()
    exercises = exercises()
    slim(:"posts/new", locals:{formatted: formatted, exercises: exercises})
  end
end


# directs you to a from with data from selected post to edit
#
# @param [integer] id, id of current post selected
# @see model#formatted
get('/posts/:id/edit') do
  id = params["id"].to_i
  formatted = formatted()
  awd = []
  i = 0
  exercises = exercises()
  while true
    a = formatted[i]
    if a[:post_id] == id
      break
    else 
      i += 1
    end
  end
  slim(:"posts/edit",locals:{id: id, post: a, exercises: exercises})
end


# takes the new data from the edit form and then updates and changes it in the database.
# 
# @param [integer] id, id of post
# @param [integer] i, the amount of exercises in the post  
# @param [String] post_name, The new name of the post
# @param [String] text, The new text in the post
# @param [String] category, the new catagory
#
# Sets, time, reps, etc is currently not working as they should. Bc of time they are not going to work
post('/posts/:id/update') do
  id = params[:id].to_i
  i = params[:i].to_i
  post_name = params[:post_name]
  text = params[:text]
  category = params[:catagory]

  posts = posts()

  posts.each do |e|
    if e['name_name'] == post_name
      content = "you need a original name"
      returnto = "/posts/index"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
    end 
  end 


  
    
  p posts


  exercises = []
  sets = []
  reps = [] 
  times = []
  hash = params
  j = 0

  while i > j

    exercise = params["exercise#{j}"]
    exercises << exercise

    set = params["sets#{j}"]
    sets << set

    rep = params["reps#{j}"]
    reps << rep

    time = params["time#{j}"]
    times << time

    j += 1

  end 
 

  db = SQLite3::Database.new('db/database.db')
      db.execute('UPDATE posts SET post_name=?,text=? WHERE id=?',post_name,text,id)

  redirect('/posts/index')

end


# Deletes post data from all tabels affected
#
# @param [integer] post_id, id of the post that is going to be deleted
post('/posts/:id/delete') do
  post_id = params[:id].to_i
  db = SQLite3::Database.new('db/database.db')
      db.execute('DELETE FROM posts WHERE id=?',post_id)
      db.execute('DELETE FROM user_post_correlation WHERE post_id=?',post_id)
      db.execute('DELETE FROM exercises_post_correlation WHERE post_id=?',post_id)
  redirect('/posts/index')
      
end


# Creates new post with params 
#
# @session [integer] sessionid, id of curret user 
# @param [String] post_name, name of new post
# @param [String] text, description / text of the new post
# @param [String] exercise, the specific exercise
# @param [String] sets, amount of sets  
# @param [String] reps, amount of reps
# @param [String] time, time in minutes 
# @param [String] catagory, catagory that the post belongs in
# @session [String] user_id, id of curret user 
post('/posts') do
  sessionid = session[:id].to_i
  if sessionid == 0
    content = "You have to login before you do that!"
    returnto = "/showlogin"
    linktext = "Try again"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else
    post_name = params[:post_name]
    text = params[:text]
    exercise = params[:exercise]
    sets = params[:sets]
    reps = params[:reps]
    time = params[:time]
    catagory = params[:catagory]
    date = publish_date = Time.now.strftime("%Y/%m/%d %H:%M")
    
    db = SQLite3::Database.new('db/database.db')
      db.execute('INSERT INTO posts (post_name, catagory, text, date) VALUES (?,?,?,?)',post_name,catagory,text,date)
    post_id = db.execute('SELECT id FROM posts WHERE post_name = ?',post_name).first

    posts = posts()
    correlation = correlation()
    user_id = session[:id].to_i

    db = SQLite3::Database.new('db/database.db')
      exercise_id = db.execute('SELECT id FROM exercises WHERE name = ?',exercise).first
      db.execute('INSERT INTO exercises_post_correlation (post_id, reps, time, sets, exercise_id ) VALUES (?,?,?,?,?)',post_id,reps,time,sets,exercise_id)
      db.execute('INSERT INTO user_post_correlation (user_id, post_id) VALUES (?,?)',user_id,post_id)
  
  


    redirect('/posts/index')
  end
end

# Create new user
#
# @param [String] name, Username
# @param [String] password, password in raw form
# @param [String] password_confirm, second time writing password 
# @see model#add_user
post('/users/new') do
  name = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  #if (username != "") && (password != "") && (password_confirm != "")
    result = check_registration(name, password, password_confirm)
    if result == "goodtogo" #Alltså om en användare med det inskriva namnet inte finns returnerar databasen nil, och då kan vi skapa en ny användare. Funktionen från model.rb returnerar 1,2 eller 3. 1 betyder good to go, skapa användare; 2 betyder att lösenorden ej matchar och 3 betyder att användaren redan finns.
      #Lägg till user:
      password_digest = BCrypt::Password.create(params[:password])
      add_user(name, password_digest)
      redirect('/showlogin')
    elsif result == "wrongpass"
      #Felhantering
      content = "Your passwords don't match, please try again."
      returnto = "/"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
    elsif result == "userexist"
      #Felhantering
      content = "This user already exists, try another username."
      returnto = "/"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
    end
end

# Gives a messae to the user that their new account has been created
get('/users/created') do
  content = "User has been created!"
  returnto = "/showlogin"
  linktext = "Login"
  slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
end

# logout from your account
# end session and resets session data
get('/logout') do 
  session[:name] = nil
  session[:id] = nil
  session[:loggedin] = false
  redirect('/')
end

# show user data
#
# @psession [integer] sessionid, id of current user
# @see model#userdata 
get('/user/show') do
  sessionid = session[:id].to_i
  if sessionid == 0
    content = "You have to login before you do that!"
    returnto = "/showlogin"
    linktext = "Try again"
    slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  else
    userdata = userdata(sessionid) 
    slim(:"/user/show",locals:{userdata:userdata})
  end 
end 


get('/user/edit') do
  id = params["id"].to_i
  userdata = userdata(id)
  p userdata
  slim(:"user/edit",locals:{id: id, userdata: userdata})
end