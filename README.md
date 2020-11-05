# EV MP MVP

Networked multiplayer asteroids-style combat in Godot.

![Two starships over a planet](https://raw.githubusercontent.com/EamonnMR/mpevmvp/master/screenshots/two_ringers.png)

Built to sort of scratch an itch: can [EV](http://escape-velocity.games) mechanics work in a multiplayer setting?

Also functions as a demo for multi-scene client/server godot projects.

Download:

https://github.com/EamonnMR/mpevmvp/releases

(windows and linux users will also need the .pck file)

Trello board where I try to track work:

https://trello.com/b/3arTIFen/mpevmvp

Assets are [Onyx's old shipyard](https://archive.org/details/onyx_shipyard), CC BY NC (plus some PD stuff; assets are as marked in folder names)

Uses the [TC Galaxy Generator](https://docs.google.com/spreadsheets/d/1kCABkT-AC6aOZoyEoub8jLrZgH8hXkeSQSwmnIXwMX8/edit#gid=1129594990) to generate galaxy.csv: 

Contains a fork of Cyberfilth's [Fantasy Names Generator](https://github.com/cyberfilth/fantasy-names-generator)

And a copy of https://github.com/binogure-studio/godot-uuid godot uuid because don't let godot's auto assigned names 
into your network code, it will mess stuff up!

Also contains a copy of https://github.com/Gianclgar/GDScriptAudioImport because otherwise loading sound from gdscript is a pain
