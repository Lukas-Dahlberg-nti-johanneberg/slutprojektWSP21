require 'sqlite3'

module Model

    # formatts all post data for use on the site 
    #
    # @return [hash] with all the data from posts table innerjoined with correlaton tables. A more exact description can be seen in the code on row 51
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

    # connects to the database and gets all avalible exercises 
    #
    # @return [hash] with all exercises
    def exercises()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        exercises = db.execute("SELECT * FROM exercises ")
        return exercises
    end

    # connects to the database and gets all avalible correlations betwen posts and exercises
    #
    # @return [hash] with exercises_post_correlation data
    def correlation()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        correlation = db.execute("SELECT * FROM exercises_post_correlation ")
        return correlation
    end

    # connects to the database and gets all data from posts
    #
    # @return [hash] with posts data
    def posts()
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        posts = db.execute("SELECT * FROM posts ")
        return posts
    end

    # connects to the database and gets all data from specifik user
    #
    # @return [hash] userdata, data over a user
    def userdata(user_id)
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true 
        userdata = db.execute("SELECT * FROM users WHERE id=?",user_id).first
        return userdata
    end

    # Verify the user so that everything is as is should be and nothing is out of order. Password is checked etc.
    # The function returns true of false depending on if the user is valid or not 
    # @param [string] name, name of user
    # @param [string] password, password of user
    # @return [boolean]
    def verify_user(name, password)
        db = SQLite3::Database.new('db/database.db')
        result = db.execute("SELECT * FROM users WHERE name=?", name).first
        if result != nil
        pw_digest = result[4]
        id = result[0]
        privilege = result[3]
        if (BCrypt::Password.new(pw_digest) == password) && (name == result[1])
            return [true, id, privilege] #Detta betyder att användaren blivit authenticatad.
        else
            return [false]
            #Fel lösenord
        end
        else 
        return [false]
        #Användaren finns ej, av säkerhetsskäl skrivs samma felmeddelande ut som vid endast fel lösenord. (Så att hackare inte vet att de träffat rätt användare)
        end
    end


    # checks if the new user is valid, username does exist and a correct password etc.
    #
    # @params [string] name, name of user
    # @params [string] password, password of user
    # @params [string] password_confirm, confirm password / no misstakes
    # @return [string] (goodtogo, wrongpass, userexist) One of these 3 is returned
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


    # Creates a user and gives privilige.
    # 
    # @return [boolean]
    def add_user(name, password_digest)
        privilege = "user" #När vi skapar en användare blir den en vanlig användare, admin-behörigheter kan erhållas senare.
        db = SQLite3::Database.new('db/database.db')
        db.execute('INSERT INTO users (name, pwdigest, privilege) VALUES (?,?,?)',name,password_digest,privilege)
        return true
    end
end
