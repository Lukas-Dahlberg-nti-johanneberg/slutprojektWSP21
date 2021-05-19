require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions 

indlude Model

before do
  sessionid = session[:id].to_i
  if  request.path_info != '/' && session[:id] == nil && request.path_info != '/error' && request.path_info != '/showlogin'
    content = "You have to login before you do that!"
      returnto = "/showlogin"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  end
  
end

get('/')  do
  slim(:register)
end 

get('/showlogin')  do
  slim(:login)
end 

post('/login') do 
  name = params[:username]
  password = params[:password]
  result = verify_user(name, password)
  if result[0] == true 
      session[:id] = result[1] #användarid:et returneras med från en array i verify_user funktionen i model.rb.
      # session[:usertype] = result[2] #Användarens usertype, d.v.s typ av användare, vilket används till authorization på flera ställen i webbapplikationen.
      session[:name] = name
      redirect('/posts/index')
  else
      content = "You have either entered the wrong password or used an invalid username."
      returnto = "/showlogin"
      linktext = "Try again"
      slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  end
end

get('/posts/index') do
  sessionid = session[:id].to_i
  p sessionid
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


    # formatted.uniq! {|w| w[:title]} #ta bort dubletter


    #second loop

    #SELECT books.name AS "book name", students.*  
    #FROM  books   
    #JOIN borrowings ON books.book_id = borrowings.book_id  
    #JOIN students ON students.student_id = borrowings.student_id;
    #p tester
    formatted.uniq!
    slim(:"posts/index",locals:{result: formatted, sessionid: sessionid})
  end
end

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
    p "awdawdawdawdawdawd"
    p formatted
    slim(:"posts/new", locals:{formatted: formatted, exercises: exercises})
  end
end

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
  p a
  slim(:"posts/edit",locals:{id: id, post: a, exercises: exercises})
end

post('/posts/:id/update') do
  id = params[:id].to_i
  i = params[:i].to_i
  post_name = params[:post_name]
  text = params[:text]
  category = params[:catagory]

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
  p id 
  p post_name
  p text
  p exercises
  p sets
  p reps
  p times

  db = SQLite3::Database.new('db/database.db')
      db.execute('UPDATE posts SET post_name=?,text=? WHERE id=?',post_name,text,id)

  redirect('/posts/index')

end

post('/posts/:id/delete') do
  post_id = params[:id].to_i
  db = SQLite3::Database.new('db/database.db')
      db.execute('DELETE FROM posts WHERE id=?',post_id)
      db.execute('DELETE FROM user_post_correlation WHERE post_id=?',post_id)
      db.execute('DELETE FROM exercises_post_correlation WHERE post_id=?',post_id)
  redirect('/posts/index')
      
end

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
  #else
  #  content = "Alla Boxes must be filled"
   # returnto = "/"
    #linktext = "Try again"
    #slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
  #end
end

get('/users/created') do
  content = "User has been created!"
  returnto = "/showlogin"
  linktext = "Login"
  slim(:message, locals:{content: content, returnto: returnto, linktext: linktext})
end

get('/logout') do 
  session[:name] = nil
  session[:id] = nil
  redirect('/')
end

