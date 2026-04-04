# Cyndrive Ships: Action/Shoot 'Em Up/Multidirectional shooters
Humanity is finally exploring the wast universe with the help of the invention of Dr. Ann Stephanie: 
The Cyndrive engine! A giant spaceship mobilizer that doubles as a time-traveling device.
It is able to move its surroundings in time, both short and long term with the use of the rare mineral, Laupeerium.
The engine is also able to generate a paradox suppression field, which makes it possible to intertwine timelines
to make smaller fighter ships be present multiple times at the same time.

Proper self-driving capabilities could not be delivered to battleships before time travel was invented, so now they send out the same guy over ondf over again to the same battle.

# Main Mechanics:
- Spaceships
- Time travel
- Bullet-hell

# Documentation
 - [Time travel implementation](doc/TIME_TRAVEL.md)

# Combat
A battle is inside an arena-like scene with environmental elements such as: planets, moons, space debris.
The player is defending a carrier ship, while fighting off enemy droid controlled ships.
The combat lasts until either the enemies or the player(alongside the carrier ship) is defeated.
Upon defeat the player can chose to restart battle, which reverts the arena to its starting state in an unstable time-bubble. 

The Battleship duplicated, each move made in the previous turn are stored and played back,
while a new ship is now controlled by the player.

# Victory
Time travel complicates who wins the battles, because even after your ship is defeated, there is the possibility to turn back time.

Time travel is bound to a time traveling engine, and powering it requires a TON of energy, 
time travel can be initiated only through the player carrier ship.
Time travel is not possible once the player carrier ship is destroyed completely, thus
the destruction of both the carrier ship and the player controlled battle ship results in losing the game.

Blowing up the carrier ship does not destroy it completely.
The player controlled battle ship has remote controls, which transcends time,
so as long as it's alive, the carrier ship can be saved by reversing time.

# Lore
There is an alloy that enables time travel, it is called Laupeerium and it is mined from asteroids.
Someone with a large carrier ship has stolen the cyndrive engine technology for time travel from the inventor of the time travel.
The technology was unpredictable enough that the thief had to join forces with the inventor.
You, the player, are being hired because flying through loops of time requires the best in the business, and the player's character believes themself to be the person for the job.
The game begins in a tutorial level that is your interview to become the pilot for these time battles.
Laupeerium is the resource required for traveling through time. Without it the time travel engine is useless.
The player utilizes a given amount of this resource, having it depleted does not automatically mean defeat,
but it takes away the power to rewind, or to restart the round.


# Story / Misc Notes
The game's story will be told through scenes of banter and dialog at the start and end of each level.
Sometimes we can focus just on the hero characters, other times we can focus mainly on the villains.
The villains are from one of the careless corporations that are trying to take all the Laupeerium for themselves.
If there are not many levels, we can focus on a main duo of villains who happened to be the ones who found our heroes and try haplessly to stop the player’s team from collecting the Laupeerium. The villain duo use a drone army, and when all of their drones are defeated they loudly escape with declarations of defeating the heroes next time.
If the game goes longer, there are villains higher up in the organization who can make an appearance. At a minimum, the higher up villains will be referenced to by the villain duo, to imply that the duo has bosses they want to impress.
The Laupeerium is either mined directly from asteroids and/or it can be found on derelict ancient spaceships from a bygone era. There is a possibility for the player to be able to win each level either by destroying enough drones so the enemies retreat, or if the heroes’ miner/reclamation team manage to get all the Laupeerium, then the heroes escape instead.
The carrier ship is owned and run by a leader who sees Laupeerium’s potential to wrest control back from the corporations, and stole the time manipulation technology to use I’m this conflict. But because the time travel technology is temperamental, the leader has had to team up with the inventor of the technology, and the inventor fights with him about how the technology should be used (and if it should be used at all).
The inventor created the technology to try and see her late mother again, but instead it was only useful for recent time travel resets. But the leader saw this technology’s potential to take their limited resources and turn one pilot into an infinite pilot in these wars.
The proposed ending of the game is her having an invention breakthrough that lets them further the time travel technology and they actually relocate one of the ancients into the present day, where they can help advance Laupeerium-use and shift the balance of power away from the foolish corporations who seek only to consume and control.
The player is the hot shot pilot who has been hired to fight these battles flying side by side with copies of the pilot, as dictated by the player’s strategies in each battle for when and how to manipulate time. The character of the pilot has not been following the rebellion against corporate galactic control, and will have many questions they need answered, which makes them a good stand-in for the player, as the player will be about as uninformed as the pilot.

# Charater notes
## Miners
The Archvillain (who the villain duo work for) is very secretive, yet bad at remembering important details.
He often sets elaborate passwords and then forgets them.
This means that his Chief Advisor must contract hackers to come in and re-gain access to his email for him- but they will see company secrets in the process,
so the Chief Advisor goes through the arduous process of having the hackers' memories wiped.
The Chief Advisor has to get a new hacker each time, because the mind-wiping process also scrambles and resets the hackers' skills;
the hackers are kept in a pen for safe keeping. The Leader managed to sneak in and liberate a bunch of the mind-wiped hackers some years ago,
and that is where the Miner/Extractors came from. The process of wiping their memories left gaps i their minds that makes them a good candidate for interfacing with Ancient technology,
because it is so alien to the present-day's sensibilities of how technology should be built.
This is also why they are a bit weird, and why the Leader will be fiercely protective of them.

## Inventor
Inventor has problems with object permanence, often information from another timeline leaks into his current conciousness,
Main motivation is to get back an important person from the time accident long ago

## Pilot
blank character, mainly to be easy fror anyone to project themselves to

## Leader
Very self motivated, likes to disregard safety rules, but not not careless: likes shortcuts
