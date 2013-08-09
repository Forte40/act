Write scripts in seconds, instead of minutes! Turtle mini-language for making scripts smaller and doing quick ad-hoc movements and builds.

2013-04-18 : v3
added history, save, build, transfer and join features
2013-01-10 : v2
added resupply ability within turtle's inventory for large builds
fixed try commands
2013-01-05 : v1

The project comes with 2 files, act and do. Copy both files to the turtle.

act - Lua API for processing act commands
do - cli (command line interface) for the act API

The act mini-language is easy and mnemonic. An act string is a sequence of commands all smashed to together, similar to a regular expression. For example, to move the turtle forward 2, turn right and go forward 3 you would use this string: "f2rf3".

Movement commands - these are 1 character in lower case. They can be followed by a number to specify how many times to move:
f - forward
b - back
u - up
d - down
r - right
l - left

Other commands - these commands are 1 character and can be followed by a number.
s - select, the number the slot the will be selected (1-16)
z - sleep (not a turtle command, but useful), the number is how many seconds to pause for
R - refuel, the number following is how much of the current slot to consume, select the correct slot number first
t - transfer, two numbers should follow separated by a comma, the first is the to slot, the second is the number of items to transfer

Action Commands - Turtles can do many actions in three directions, forward, up and down. The following commands are all 2 characters where the second character is the direction (f-forward, u-up, d-down). The first character is upper case and the second is lower:
D - dig (Df, Du, Dd)
P - place (Pf, Pu, Pd)
B - build (Bf, Bu, Bd) (just like place, but attempts to resupply a slot if using the last item)
E - drop (E for eject) (Ef, Eu, Ed)
A - attack (Af, Au, Ad)
S - suck (Sf, Su, Sd)

Decision Commands - Turtles can detect blocks and compare blocks to their inventory. These commands 2 characters which are a symbol followed by a direction (f, u, d). These will stop the current action block from continuing:
? - detect (?f, ?u, ?d)
= - compare (=f, =u, =d) (use the select command to pick the block to compare with first

Parenthesis

You can use parenthesis () to group some actions and repeat them. "(Pfuf)5" will build a staircase for you if your turtle has stairs in the selected slot. The turtle will place a block forward, move up, move forward, then repeat the process a total of 5 times. Parenthesis can be nested.

Join

You can have a turtle perform a series of actions between iterations of commands.  Use a slash ( / ) inside of parenthesis.  The join action will only be performed between iterations, so you would need at least 2 for it to execute.  "(f2/r)4" will cause the turtle to move in a square shape, moving forward 4 times for each side, but only turning right 3 times.  The join is useful when building, such as a floor.  "(Pd/f)10" will place 2 blocks down.  The turtle can start on the first square and end on the last square without having to move forward once at the beginning or moving an extra space at the end.

do is the command line interface. You can quickly give your turtle a few commands. For example, if your turtle is on top of a block and you'd like to move it below the block you can type the following:

do bd2f

The turtle will back up, move down 2 below the block, then move back forward under the block.

do history

This will list all the recent commands that have been executed.  Commands are stored in the file .acthistory

do save <name>

This will save the latest (and greatest?) command with a name so you can reference it later.  Named commands are stored in the file .actsaved

act is the api that you can use in your scripts. To do the same actions in a script, put the following in a file:

os.loadAPI("act")
act.act("bd2f")

Here is an example script to chop down a tree. After placing a turtle in front of a tree trunk, we want the turtle to chop (dig) the first log at the bottom, move underneath the trunk, then chop up to the top, then come back down. We'll repeat the dig up and move up commands as long as we detect a block above us. If the ?u (detectUp) fails, the action will skip out of the repeated loop and move on to going down 48. If the tree is not 48 blocks high, the turtle will move down to the ground, then fail to continue moving, which is good enough for us to retrieve it. (Unless there is a hole below the tree?)

do Dff(?uDuu)48d48