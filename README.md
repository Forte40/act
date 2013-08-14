Write scripts in seconds, instead of hours! Turtle mini-language for making scripts smaller and doing quick ad-hoc movements and builds.

1)  Features:

	* Multi-turtle scripts are easy
	* Session persistance (coming soon)
	* GPS sync or relative positioning with waypoints and absolute locations
	* Easily move a turtle ad-hoc, similar to the go command
	* Save useful commands as macros
	* Multi-line mode for easy typing
	* Macro mode, perform several command and check turtle behavior, then save
	* Ability to create script files with comments
	* Turtle enhancements can be used without the act script language in normal lua code

2)  Tutorial:

    1) Basic Movement:

		The basic commands are easy to use and memorize.  First we will move the turtle around.

		f = forward
		b = backward
		u = up
		d = down
		l = turn left
		r = turn right

		To move the turtle forward 3, then turn around and come back, use the command:

		f f f r r f f f

		We can make it easier by puting a number after an 'action' like this:

		f3 r2 f3

		Notice how we used the action 'f3' twice with the action 'r2' between?  That is similar the the lua code 'string.join(list, separator)'.  We can use a join feature of the act language to do this:

		(f3 / r2) 2

		The 'f3' action will be repeated 2 times and between each repetition it will perform the action 'r2'.

		Notice how we used parenthesis to group actions and repeat the whole group?  Here is how we can make the turtle go in a square pattern:

		(f3 r) 4

		The turtle turned right 4 times, so it will be facing the same direction that it started.  If we only cared about coming back to the same location and not the direction the turtle is facing, we can cut out the last turn using the join syntax:

		(f3 / r) 4

		This could be useful when building inside of a room.  If you wanted to put a floor down, you have to stay inside the walls, so you can't have an extra move at the beginning or end of the loop.  This command will call turtle.placeDown 8 times and move between placements for 7 movements.

		(Pd / f) 8

	2)  Basic Turtle Commands:

	    Basic turtle commands map directly to the turtle api:

	      Pf = place                                 
	      Pd = placeDown                             
	      Pu = placeUp                               

	      Df = dig                                   
	      Dd = digDown                               
	      Du = digUp                                 

	      Af = attack
	      Ad = attackDown
	      Au = attackUp

          (D is used for dig, so we use E(eject) for drop)
	      Ef = eject     (drop)
	      Ed = ejectDown (dropDown)
	      Eu = ejectUp   (dropUp)

	      Sf = suck
	      Sd = suckDown
	      Su = suckUp

	      Cf = compare
	      Cd = compareDown
	      Cu = compareUp
	      c  = compareTo <slot>

	      (D is used for dig, so we use H(hit) for detect)
	      Hf = hit     (detect)
	      Hd = hitDown (detectDown)
          Hu = hitUp   (detectUp)

          (I is used for inspect, commands that don't cause turtle actions)
          If = inspectFuel  (getFuelLevel)
          Ic = inspectCount (getItemCount)
          Is = inspectSpace (getItemSpace)

          These commands take one or more parameters, separated by a comma

          s  = select <slot>
          (r is used for turnRight, so we use e(eat) for refuel)
          e  = eat <amount>  (refuel)
          t  = transferTo <slot> , <amount>
          c  = compareTo <slot>
          o  = output (print)

          With these turtle commands, we can attempt to make a tree chopper.  Using a fueled turtle in front of a tree and the do command, try the following:

          	do Df f (Du u)10 d10 b

          This will dig forward then move forward under the trunk.  Then we dig up and move up 10 times.  Then we come back down 10 and move back to the original starting position.  If the turtle has saplings in slot 1 and bonemeal in slot 3, we can try to grow the tree again.

          	do s1 Pf s2 Pf3 -- use bonemeal three times just in case

          We can repeat the whole thing forever using the infinite loop '*'.

          	do (Df f (Du u)10 d10 b s1 Pf s2 Pf3)*

          Of course we will run out saplings or bonemeal at some point.  Also, we can only chop trees of height 10 or less.  Let's fix that.  Instead of moving up only 10, we will move up until we don't detect other blocks.  Assuming there is dirt under the tree, we can just move down until blocked as well.

          	do (Df f (?Hu Du u)* (~Hd d)* b s1 Pf s2 Pf3)*

          The '?Hu' action will check if there is a block above the turtle (detectUp) and if there is, continue the loop.  Otherwise it will break out of the loop and move to the next action.

          Of course we are wasting fuel by digging through leaves, so we can try and compare the logs to stop a little sooner.  Assuming slot 3 is empty or has logs when we start we can do the following:

          	do (Df f s3 (?Cu Du u)* (~Hd d)* b s1 Pf s2 Pf3)*

          Nice.

    3)  Enhanced Turtle Commands

    	Enhanced turtle commands combine the basic commands with some logic.

		Bf = build     (place with resupply from a different slot if it is the last item)
		Bd = buildDown (uses the compare feature of the turtle)
		Bu = buildUp

		Mf = move     (move with anti-gravel/mob logic)
		Md = moveDown (try moving, otherwise keep digging or attacking until success)
		Mu = moveUp

		Gf = go     (move and wait patiently forever if blocked)
		Gd = goDown
		Gu = goUp
		G<> = go to location or waypoint

		With these commands we can shorten the tree script a little.  Instead of digging and then moving with 2 actions, we can use one.  Also, if a sheep wanders under us while chopping, we can smack it out of the way.

			do (Mf s3 (?Cu Mu)* (~Hd d)* s1 Pf s2 Pf3)*

	4)  Waypoints

	    Waypoints are named location using x, y, z and facing direction.  Go to a location and set a waypoint using:

	    w = set waypoint <name>

	    You can then tell your to navigate to the waypoint:

	    G<> = go to waypoint <name>

	    You can also use coordinates if you don't have a saved waypoint.  This uses the parameters x, y, z and facing.  A facing of 0 is south, just like in minecraft.

	    G<0,0,0,2>
	    G<4,-5,7,0>

	    You can use absolute coordinates if you have a gps system setup using the gps extension

	    %gps%
	    %gps,true%

	    If a paramenter is passed to gps, then it will move the turtle forward once to see which way it is facing.

	    Let's make a change to the tree script for coming back down.  We will set a waypoint at the start of the script:

	    	do w<home> (Mf s3 (?Cu Mu)* G<home> s1 Pf s2 Pf3)*

	    That script is looking nicer.

	5)  Extensions

	    Extensions are the ability to call normal lua code from within the act script.  The extension name is surrounded by '%' characters.  Extensions can take any number of string parameters separated by commas.  The lua code will need to know how to deal with the parameters and convert strings to numbers or booleans if needed.

	    The gps extension is built in:

	    %gps% = sync turtle to gps
	    %gps,true% = sync turtle to gps, move forward to get facing direction

	    The request extension is built and instructs a turtle to check its inventory for the correct levels.  3 parameters must be passed where the first and third should be numbers.  You can repeat this several times for checking for multiple resources.  The turtle will pause if more is needed and wait.

	    %request,slot,description,amount%

	    Extensions can also be used as sub routines in act scripts.  Use the variable syntax to save a grouping of actions to an extension

	    	(f b l r)=%newextention%

	    Let's use the built request extension to make our tree turtle better.  We will request slot 1 has 1 sapling and slot 2 has 3 bonemeal before beginning each loop.  This will make the turtle pause for refilling before wasting fuel chopping down a non-existant tree.  If we put extra supplies in, it will not pause.  Also, if we use the build action rather than the place action, the turtle will pull extra resources into slot 1 and 2 for us automatically by comparing to other slots that may have the same item.  We are also going to use the multi-line mode for easier reading:

		    do [[
		      w<home>                               -- set waypoint
		      (                                     -- chopping loop start
		      	%request,1,saplings,1,2,bonemeal,3% -- get stuff
		      	Mf s3 (?Cu Mu)*                     -- chop tree
		      	G<home>                             -- go back home
		      	s1 Bf s2 Bf3                        -- plant new tree
		      )*
		    ]]

	6)  Variables

		Variables are a '#' for number or a '$' for boolean followed by a single character.  They are case sensitive and global, so you get 52 total variables in a script.  (If you need more...use lua?)

	    Variables are useful for saving the results of an action or the number of times a loop repeated.  We can use a number variable for counting the height of our tree.  (Let's go back to the simpler script.)  We will switch out the waypoints for a count of the tree height for going back.

	    	do (Mf s3 (?Cu Mu)*=#h d#h b s1 Bf s2 Bf3)*

	    Here we save the number of time the chopping loop ran to variable #h (for height) and then after that we go down that many times.  You can also save the results of a compare or detect to a boolean variable to use later

	    	do Cf=$a (?$a f)

    7)  Saving

			do history

		This will list all the recent commands that have been executed.  Commands are stored in the file .act.history

			do save <name>

		This will save the latest (and greatest?) command with a name so you can reference it later.  Named commands are stored in the file .act.macro

	8)  Macros

	    do macro <name>

	    This will start the turtle in interactive mode.  You can give the turtle commands, hit enter, and watch and verify the results.  Enter ']]' to end macro mode and save the command.

	    In macro mode, you can do a few things different than in normal scripts

	    	)3

	    This command by itself will repeat the last line three times.  Since you already entered the last line in, the turtle will continue it 2 more times, then wait.

	    	2 )3

	    This command will group the previous 2 lines and then repeat the group 3 times.  Again, the turtle will perform this 2 more times since it already did it once.

	    	/ f ) 3

	    This will repeat the previous command 3 times with an additional join command in between.

	    	2 / f ) 3

	    This will group the previous 2 lines and repeat 3 times with a join command.

	9)  API

			os.loadAPI("apis/act")

		The act api can be used from within normal lua scripts.

			act.act("w<home> (Mf s3 (?Cu Mu)* G<home>)")

		You can also parse and act string and get the abstract syntax tree (ast)

			local ast = act.parse("w<home>")
			act.tprint(ast)

		You can then interpret the ast separately:

			act.interpret(ast)

		The act api enhances the turtle so you can use waypoints and positioning easily without actually using act scripts (but why not!).

			turtle.gps(true)
			print(turtle.x, turtle.y, turtle.z, turtle.facing)
			for i = 1, 3 do
				turtle.forward()
				turtle.turnLeft()
			end
			print(turtle.x, turtle.y, turtle.z, turtle.facing)
			turtle.select(4)
			print(turtle.selected)
			turtle.setWaypoint("home")
			for i = 1, 10 do
			    turtle.forward()
			end
			turtle.go("home")
			for name, waypoint in pairs(turtle.waypoint) do
			    print(name, waypoint.x, waypoint.y, waypoint.z, waypoint.facing)
			end
			turtle.go(0,0,0,0)


3)  Installation

	Get the installer at http://pastebin.com/5CuUMxqr using the command:

	  pastebin get 5CuUMxqr act-install

	The install script can install and upgrade the system for you.

	The project comes with 6 files:

	  1) act-install: installer and upgrader
	  2) act        : api

	  the basic script files
	  do         : CLI for ad hoc and macro mode turtle commands
	  forman     : controller script for multi-turtle scripts
	  worker     : worker script for multi-turtle scripts
	  startup    : startup script for initializing turtles for a multi-turtle script, act and do.

4)  History

	2013-08-13 : v2.0
	Major rewrite
	  PEG grammer with recursive decent parser - makes for faster language changes
	    comments and whitespace
	  Multi-turtle scripts
	  	parallel and sequential processing of commands for different turtles
	  	startup script for naming, fueling, positioning and starting multi-turtle scripts
	  Macro mode with repeating several lines
	  Installer and updater
	2013-04-18 : v3
	added history, save, build, transfer and join features
	2013-01-10 : v2
	added resupply ability within turtle's inventory for large builds
	fixed try commands
	2013-01-05 : v1
	2012-12-30 : totally saw Guude enter 'go forward 3' and said to myself 'I can do better'
