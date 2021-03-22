require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions 

get('/')  do
  slim(:register)
end 


get('/showlogin')  do
  slim(:login)
end 


post('/login') do 
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE name = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id 
    redirect('/posts')
  else
    "Fel lösen"
  end

end 


get('/posts') do
  sessionid = session[:id].to_i
  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  # alldata = db.execute("SELECT * FROM exercises WHERE id = ?",id).first
  exercises = db.execute("SELECT * FROM exercises")

  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true 
  posts = db.execute("SELECT * FROM posts")

  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true 
  relation = db.execute("SELECT * FROM exercises_post_correlation")

  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true 
  tester = db.execute("SELECT *


  FROM posts
  INNER JOIN exercises_post_correlation ON posts.id = exercises_post_correlation.post_id
  INNER JOIN exercises ON exercises_post_correlation.exercise_id = exercises.id
  ")



#SELECT books.name AS "book name", students.*  
#FROM  books   
#JOIN borrowings ON books.book_id = borrowings.book_id  
#JOIN students ON students.student_id = borrowings.student_id;


  
  




  p "TITTA HÄR #{tester}"
  slim(:"posts/index",locals:{result:exercises,result2:posts,result3:relation,result4:tester})
  
end


post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/database.db')
    db.execute("INSERT INTO users (name,pwdigest) VALUES (?,?)",username,password_digest)
    redirect('/')
  else 
    #felhantering
    "lösenordet matchade inte"
  end

end

