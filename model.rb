require 'sqlite3'

module Model
    def formatted()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        tester = db.execute("SELECT *

        FROM posts
        INNER JOIN exercises_post_correlation ON posts.id = exercises_post_correlation.post_id
        INNER JOIN exercises ON exercises_post_correlation.exercise_id = exercises.id
        INNER JOIN user_post_correlation ON posts.id = user_post_correlation.post_id
        ")

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
        formatted.uniq!

        return formatted
    end

    def exercises()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        exercises = db.execute("SELECT * FROM exercises ")
        return exercises
    end

    def correlation()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        correlation = db.execute("SELECT * FROM exercises_post_correlation ")
        return correlation
    end

    def posts()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        posts = db.execute("SELECT * FROM posts ")
        return posts
    end

    def verify_user(name, password)
        db = SQLite3::Database.new('db/database.db')
        result = db.execute("SELECT * FROM users WHERE name=?", name).first
        if result != nil
        pw_digest = result[4]
        id = result[0]
        privilege = result[3]
        if (BCrypt::Password.new(pw_digest) == password) && (name == result[1])
            return [true, id, privilege] #Detta betyder att användaren blivit authenticatad. Normalt brukar jag hämta ytterligare data om användaren via nya SQL-anrop men jag ansåg det rimligt att hålla användarnamn, id, och usertype med i sessions då dessa kan komma att behövas frekvent under användarens besök på hemsidan.
        else
            return [false]
            #Fel lösenord
        end
        else 
        return [false]
        #Användaren finns ej, av säkerhetsskäl skrivs samma felmeddelande ut som vid endast fel lösenord. (Så att hackare inte vet att de träffat rätt användare)
        end
    end

    def check_registration(name, password, password_confirm)
        db = SQLite3::Database.new('db/database.db')
        result = db.execute("SELECT * FROM users WHERE name=?", name).first
        if result == nil
            if password == password_confirm
                return "goodtogo" #Good to go, bara att skapa användaren.
            else
                return "wrongpass" #Lösenorden matchar inte
            end
        else
            return "userexist" #Användaren finns redan
        end
    end

    def add_user(name, password_digest)
        privilege = "user" #När vi skapar en användare blir den en vanlig användare, admin-behörigheter kan erhållas senare.
        db = SQLite3::Database.new('db/database.db')
        db.execute('INSERT INTO users (name, pwdigest, privilege) VALUES (?,?,?)',name,password_digest,privilege)
        return true
    end
end
