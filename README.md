# EV MP MVP

Networked multiplayer Space Trading/Combat game with asteroids style mechanics and a procedurally generated world. Built in Godot using free graphics.

![Spaceship combat](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/gameplay.jpg)

Built to sort of scratch an itch: can [EV](http://escape-velocity.games) mechanics work in a multiplayer setting?

Also functions as a demo for multi-scene client/server godot projects.

Some more screenshots:

![Landing](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/landing.jpg)

Download:

https://github.com/EamonnMR/mpevmvp/releases

(windows and linux users will also need the .pck file)

Trello board where I try to track work:

https://trello.com/b/3arTIFen/mpevmvp

![screenshot of landing view](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/landing.jpg)

Assets are [Onyx's old shipyard](https://archive.org/details/onyx_shipyard), CC BY NC (plus some PD stuff; assets are as marked in folder names) and [Lost Garden's Hard Vaccum](http://www.lostgarden.com/2005/03/game-post-mortem-hard-vacuum.html).

![screenshot of the map](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/procgen_map.jpg)

Uses the [TC Galaxy Generator](https://docs.google.com/spreadsheets/d/1kCABkT-AC6aOZoyEoub8jLrZgH8hXkeSQSwmnIXwMX8/edit#gid=1129594990) to generate galaxy.csv. For info see [this blog post](https://orion-skies.blogspot.com/2020/11/tactics-systems-galaxy-generators.html)

Contains a fork of Cyberfilth's [Fantasy Names Generator](https://github.com/cyberfilth/fantasy-names-generator)

And a copy of [Godot uuid](https://github.com/binogure-studio/godot-uuid) because don't let godot's auto assigned names 
into your network code, it will mess stuff up!

Also contains a copy of [GDScript Audio Import](https://github.com/Gianclgar/GDScriptAudioImport) because otherwise loading sound from gdscript is a pain.
