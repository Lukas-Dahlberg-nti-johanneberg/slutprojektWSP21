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
  id = session[:id].to_i
  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  result = db.execute(SELECT * FROM )
  slim(:"posts/index")
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

