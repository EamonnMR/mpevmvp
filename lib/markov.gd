# Forked from From: https://github.com/cyberfilth/fantasy-names-generator/blob/master/Markov/Markov.gd

#MIT License

#Copyright (c) 2019 Chris Hawkins

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

extends Node

var names = [
"Etobicoke",
"Laconia",
"Furuseth",
"Sanstuba",
"Nassau",
"Levar",
"Crozier",
"Kirkham",
"Battle",
"Pierre",
"Winston",
"Hairston",
"Felder",
"Shreve",
"Bialik",
"Lydian",
"Merrimack",
"Laconia",
"Lyrell",
"Harkham",
"Sweckard",
"Kecksburg",
"Paducah",
"Poplar",
"Fallingwater",
"Frostridge",
"Aundrel",
"Cantwell",
"Rivest",
"Fairhaven",
"Nashua",
"Laramide",
"Tuckahoe",
"Hopmeadow",
"Tuolumne",
"Coldwater",
"Nightside",
"Brokenhill",
"Courthope",
"Courci",
"Scanlon",
"Dust",
"Stavros",
"Fonseca",
"Inverness",
"Holcomb",
"Renbrook",
"Quinten",
"Zero",
"Xavarian",
"Yonkers",
"Juniper"
]

var alphabet = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']

var markov = {}

var rng = RandomNumberGenerator.new()

func loadNames(markov, names):
	for name in names:
		var currName = name
		for i in range(currName.length()):
			var currLetter = currName[i].to_lower()
			var letterToAdd;
			if i == (currName.length() - 1):
				letterToAdd = "."
			else:
				letterToAdd = currName[i+1]
			var tempList = []
			if markov.has(currLetter):
				tempList = markov[currLetter]
			tempList.append(letterToAdd)
			markov[currLetter] = tempList

func getName (firstChar, minLength, maxLength):
	var count = 1
	var name = ""
	if firstChar:
		name += firstChar
	else:
		var random_letter = alphabet[rng.randi_range(0, alphabet.size()-1)]
		name += random_letter
	while count < maxLength:
		var new_last = name.length()-1
		var nextLetter = getNextLetter(name[new_last])
		if str(nextLetter) == ".":
			if count > minLength:
				return name
		else:
			name += str(nextLetter)
			count+=1
	return name

func getNextLetter(letter):
	var thisList = markov[letter]
	return thisList[rng.randi_range(0, thisList.size()-1)]

func _ready():
	loadNames(markov, names)

func get_random_name(_list: String, seed_value: int) -> String:
	rng.seed = seed_value
	var random_letter = alphabet[rng.randi_range(0, alphabet.size()-1)]
	var new_name = getName(random_letter, 4, 7)
	new_name = new_name.capitalize()
	# print("Seed: ", seed_value, " Result: ", new_name)
	return new_name
