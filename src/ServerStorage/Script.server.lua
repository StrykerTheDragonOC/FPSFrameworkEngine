local Animal = { --superclass
	Name = "Unknown",
	Sound = "Silent",
	
}
Animal.__index = Animal

function Animal:Speak()
	print(self.Name.." says "..self.Sound)
	
	
end

local Cat = {}
Cat.__index = Cat
setmetatable(Cat, Animal)
Cat.Name = "Cat"
Cat.Sound = "Meow"

function Cat:Sneak()
	print(self.Name.." is sneaking around. ")
end

local myCat = setmetatable({}, Cat)
myCat:Speak()
myCat:Sneak()
