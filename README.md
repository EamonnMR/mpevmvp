# EV MP MVP

Networked multiplayer Space Trading/Combat game with asteroids style mechanics and a procedurally generated world. Built in Godot using free graphics.

![screenshot of gameplay](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/gameplay.png)

Built to sort of scratch an itch: can [EV](http://escape-velocity.games) mechanics work in a multiplayer setting?

Also functions as a demo for multi-scene client/server godot projects.

Download:

https://github.com/EamonnMR/mpevmvp/releases


Make sure you host a server then run another instance of the game and join it as a client. Make sure you've opened the port on your router! (default port is 26000!)

(windows and linux users will also need the .pck file)

![screenshot of store](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/store.png)

Trello board where I try to track work:

https://trello.com/b/3arTIFen/mpevmvp

![screenshot of landing view](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/landing.png)

Assets are [Onyx's old shipyard](https://archive.org/details/onyx_shipyard), CC BY NC (plus some PD stuff; assets are as marked in folder names) and [Lost Garden's Hard Vaccum](http://www.lostgarden.com/2005/03/game-post-mortem-hard-vacuum.html).

![screenshot of the map](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/map.png)

Uses the [TC Galaxy Generator](https://docs.google.com/spreadsheets/d/1kCABkT-AC6aOZoyEoub8jLrZgH8hXkeSQSwmnIXwMX8/edit#gid=1129594990) to generate galaxy.csv. For info see [this blog post](https://orion-skies.blogspot.com/2020/11/tactics-systems-galaxy-generators.html)

Contains a fork of Cyberfilth's [Fantasy Names Generator](https://github.com/cyberfilth/fantasy-names-generator)

And a copy of [Godot uuid](https://github.com/binogure-studio/godot-uuid) because don't let godot's auto assigned names 
into your network code, it will mess stuff up!

