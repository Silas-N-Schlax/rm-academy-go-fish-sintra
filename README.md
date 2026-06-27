# Go-Fish (Sinatra and Rack)

> Simple Go-Fish application to play with up to 6 players with UI. Has basic API support for bots to be added to play against players (requires 1 web user to start the game).


## Using This App


Install
```
git clone https://github.com/Silas-N-Schlax/rm-academy-go-fish-sintra.git
```

CD into the directory
```
cd rm-academy-go-fish-sintra.git
```

Bundle
```
bundle install
```


### Running the server and joining on local machine only

Run the Server
```
rackup
```

Open in browser
```
https://localhost:9292
```

*To start a game join in a different browser or in a private window to clear your session api_key*

Add a bot
```
ruby lib/go-fish/bot/runner.rb
```
*If the bot keeps sending a message joined but with no api_token restart the bot, it means that name is already taken and it is being rejected.*


### Running the server and joining on any machine on the same network


Run the Server
```
rackup -o 0.0.0.0 -p 4567
```

Open in the browser

1. Find your ip address on that network.
2. Go to the url `http://<you_ip>:4567`
3. Play the game!


### Why This project was made:

This project was created as an assignment from the Craftsmanship Academy I participated in in 2026. This was one of many projects but focused on Sinatra, Slim (html), and Test-Driven Development (TDD) along with using techniques such as BEM for our css and Optics (an open sourced CSS library developed by RoleModel Software).
