This repo contains my "starting point project" for games or other Lua software written using the [LÖVR](http://lovr.org) VR games engine. The contents were written by me, Andi McClure <<andi.m.mcclure@gmail.com>>, with some open source libraries included, and are the basis for games under development for [Mermaid Heavy Industries](https://mermaid.industries).

The software in here is mostly a hodgepodge of "whatever I need", but the core is an entity tree library, hence the name. Also included are 

* A simple 2D UI library for LÖVR's on-monitor "mirror" window, useful for debug UI.
* Modified versions of the [CPML](https://github.com/excessive/cpml) (vector math) and [Penlight](https://github.com/stevedonovan/Penlight) (classes and various Lua utilities) libraries
* My [namespace.lua](https://bitbucket.org/runhello/namespace.lua) library

A map of all included files is in [contents.txt](lua/contents.txt). The license information is (here)[LICENSE.txt]. I have a page with more LÖVR resources (here)[https://mcclure.github.io/mermaid-lovr/].

# Why use this?

Let's take a look at the "cube.lua" example program packaged in the repo:

	-- Simple "draw some cubes" test
	namespace("cubetest", "standard")

	local CubeTest = classNamed("CubeTest", Ent)
	local shader = require "shader/shader"

	function CubeTest:onLoad(dt)
		self.time = 0
	end

	function CubeTest:onUpdate(dt)
		self.time = self.time + math.max(dt, 0.05)
	end

	function CubeTest:onDraw(dt)
		lovr.graphics.clear(1,1,1) lovr.graphics.setShader(shader)

		local count, width, spacing = 5, 0.4, 2
		local function toColor(i) return (i-1)/(count-1) end
		local function toCube(i) local span = count*spacing return -span/2 + span*toColor(i) end

		for x=1,count do for y=1,count do for z=1,count do
			lovr.graphics.setColor(toColor(x), toColor(y), toColor(z))
			lovr.graphics.cube('fill', toCube(x),toCube(y),toCube(z), cubeWidth, self.time/8, -y, x, -z)
		end end end
	end

	return CubeTest

If you've already used LÖVR, this looks a lot like a normal LÖVR program-- instead of implementing `lovr.update()` it implements `CubeTest:onUpdate(dt)`. But it's done a little different and this gives us some neat advantages. Because this program is enclosed in an object (an "entity"), we could swap it out for another "entity" program very easily, or run it at the same time as another "entity" program. In my main game project, I have a variety of small helper programs in the same repo, that let me test or edit various parts of the game; I use the command line to decide which one I want to run. Below there's an example where the command line is used to tell lovr-ent to run the cubes program at the same time as another program that displays the FPS in the corner. It would also be easy to write a program where the main program's "entity" loaded a copy, or several copies, of the CubeTest entity as children and presented them in a scene.

You'll also notice the "namespace" tag at the top of the file. This takes away the risk of accidentally letting globals from one file contaminate other files-- globals will only be shared between the `.lua` files that start with `namespace "cubetest"`.

# How to use this

You want to copy the `lua` folder in this repo into your own repo (or just develop inside this repo if you want to be able to merge future updates). If you're using lovr-oculus-mobile, you could also add the path to this repo's `lua` folder to `assets.srcDirs` in "build.gradle" and the files will be merged with yours when you build.

You should take a look at [main.lua](lua/main.lua). There's some stuff here you probably want to change: There's a list of modules imported from CPML and Penlight. There's a section labeled "Suggest you create a namespace for your game here", which you probably want to uncomment, and set up the globals for your own game's namespace there. You also want to change the "defaultApp" variable to point to your main Ent.

Now you'll want to start adding your own .lua files to the project, for your main Ent and any helper stuff your game needs. I use the `app/` directory to store entities that could potentially be run alone as the main Ent, an `ent/` directory to store reusable entities that another Ent might load as a child, the `engine/` directory to store other helper files, and `level/` and `resource/` directories to store my helper files. But you can do whatever.

## Using Ents

The first thing to know is Ents are classes, using the Penlight class library (see [here](https://stevedonovan.github.io/Penlight/api/libraries/pl.class.html), or "Simplifying Object-Oriented Programming in Lua" [here](https://stevedonovan.github.io/Penlight/api/manual/01-introduction.md.html)). You probably need to understand what "Classes", "Objects", "Inheritance" and "Instances" are to go any further, and you need to understand the difference between `.` and `:` in Lua.

Entities are instances of `Ent`, or a class inheriting from `Ent`. Every entity keeps a list of child entities. When events occur-- the program boots, there is an update, it is time to draw-- those events are "routed" to every Ent, starting with the "root" ent. Some events are:

	* onLoad: Equivalent of lovr.load
	* onUpdate: Equivalent of lovr.update
	* onDraw: Equivalent of lovr.draw
	* onMirror: Equivalent of lovr.mirror

If, say, "onDraw" fires, then for each entity starting with `ent.root` that entity calls its `onDraw()` function (if it has one), and then for each of its children in turn they call their `onDraw()` (if they have one) and repeat with their children. (The children don't get called in any particular order, except for entities that inherit from `OrderedEnt`.) You can route an event to every object yourself by calling `ent.root:route("onEventName", OPTIONALARGS)`, and every loaded entity will get the function call onEventName(OPTIONALARGS). 

So Ents live in a tree of entities. If you've used Unity, Ents are kind of like a combination of Components, gameObjects and scenes. (You can't at the moment give an Ent an inheritable "transform" or world position, but this may appear in a later version of lovr-ent.)

To create an Ent, you call its constructor; the default constructor for Ents takes a table as argument, and assigns all fields to the entity object. So if you say `YourEnt{speed=3}`, this creates a YourEnt object where `self.speed` is 3 in all methods. Once you've constructed the Ent, you need to insert it to add it to the tree: call `insert( PARENT )` with the . If you don't list a parent the entity will automatically add itself to `ent.root`, but usually Ents will be created by methods of other Ents, so you'll want to set `self` as the parent.

By the way, **the "onLoad" event is special**. It is called not just when `lovr.onLoad()` is called, but also when any object is `insert()`ed to an object which is a child of the root if `lovr.onLoad()` has already been called. This means most of the things you'd normally do in a constructor, like setting default values for variables, it's smarter to do in `onLoad`, since that code will be called only when the object "goes live".

When you're done with an Ent, call `yourEnt:die()`. This registers your ent to be removed from the tree (which will remove all its children as well) at the end of the current frame. You'll get an "onDie" event call if you or one of your parents gets `die`d, which you can use to do any cleanup.

By the way, a cool thing about the Ent default constructor is that you can do one-off entities by overloading the event methods in the constructor. Here's what I mean:

    Ent{ onUpdate = function(self, dt) print("Updated! dt:" .. dt) end }:insert()

Running this code will create and attach to the root an object that prints the current frame's timestep on every frame.

Although lovr-ent is tied in pretty closely with LÖVR, there's nothing LÖVR-specific about the ent system itself. You could pull "engine/ent.lua" out and use it in a non-LÖVR project, and in fact ent.lua is just a rewrite of similar systems I've previously used in the [Polycode](https://bitbucket.org/runhello/polyconsole) and [UFO](https://bitbucket.org/runhello/ufo/wiki/Home) LUA frameworks.

### Using LoaderEnt

LoaderEnt is a built-in entity that loads and runs Ent classes from disk. The root entity is a LoaderEnt, and it loads the classes in the command line. So if you launch your game by running:

    lovr lovr-ent/lua app/test/testUi

Then lovr-ent will load and run the class in the file "app/test/testUi.lua" (it will `require()` "app/test/testUi", construct the class it returns, and call `insert()`). We can get fancier if we download and add in my other LÖVR helper tool, (Lodr)[https://github.com/mcclure/lodr]:

    lovr lovr-lodr lovr-ent/lua app/test/cube app/debug/hand app/debug/fps

What's happening here? Well, lovr loads Lodr, which loads lovr-ent, which loads each of the "cube" sample app, and two helper apps that respectively display the handset controller in 3D space and display the current FPS in 2D space (in the "mirror" window on your screen). So now you've got the cube running, but with these two nice helpers that let you see the controller and the FPS; and also, because Lodr is watching the files for changes, you can change "cube.lua" and save and any changes will pop on your VR headset in realtime. This is the way I develop my games.

In order for LoaderEnt to load a .lua file, the .lua file needs to return a Ent **class**, like the cube.lua example up there does. LoaderEnt can also load specially formatted .txt files, where each line is one path to something LoaderEnt knows how to load (a class .lua or txt file).

### Doom

## Using namespaces

## Other misc stuff

## How to use the UI2 library