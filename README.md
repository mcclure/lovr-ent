This repo contains my "starting point project" for games or other Lua software written using the [LÖVR](http://lovr.org) VR games engine. The contents were written by me, Andi McClure <<andi.m.mcclure@gmail.com>>, with some open source libraries included, and are the basis for games under development for [Mermaid Heavy Industries](https://mermaid.industries).

The software in here is mostly a hodgepodge of "whatever I need", but the core is an entity tree library, hence the name. Also included are 

* A system for loading and running entity objects as "apps", with optional command line arguments passed to apps directly
* A simple 2D UI library for LÖVR's on-monitor "mirror" window, useful for debug UI.
* A minimal 3D UI library using the same widget and layout objects as the 2D one
* Modified versions of the [CPML](https://github.com/excessive/cpml) (vector math) and [Penlight](https://github.com/stevedonovan/Penlight) (classes and various Lua utilities) libraries
* My [namespace.lua](https://bitbucket.org/runhello/namespace.lua) library
* Helper code for making thread tools, and one class for offloading asset loading onto a side thread
* A debug class for placing temporary cube and line markers at important points in space
* A standalone app to preview 3D model files and inspect their materials, animation nodes and animations.

A map of all included files is in [contents.txt](lua/contents.txt). The license information is [here](LICENSE.txt). I have a page with more LÖVR resources [here](https://mcclure.github.io/mermaid-lovr/).

This code assumes LÖVR version 0.13.

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

If you've already used LÖVR, this looks a lot like a normal LÖVR program-- instead of implementing `lovr.update()` it implements `CubeTest:onUpdate(dt)`. But it's set up a little different and this gives us some neat advantages. Because this program is enclosed in an object (an "entity"), we could swap it out for another "entity" program very easily, or run it at the same time as another "entity" program. In my main game project, I have a variety of small helper programs in the same repo, which let me test or edit various parts of the game; I use the command line to decide which ones I want to run. Below there's an example where the command line is used to tell lovr-ent to run the cubes program at the same time as another program that displays the FPS in the corner. It would also be easy to write a program where the main program's "entity" loaded a copy, or several copies with different parameters, of the CubeTest entity as children and presented them in a scene.

You'll also notice the "namespace" tag at the top of the file. This takes away the risk of accidentally letting globals from one file contaminate other files-- globals will only be shared between the `.lua` files that start with `namespace "cubetest"`.

# How to use this

You want to copy the `lua` folder in this repo into your own repo (or just develop inside this repo if you want to be able to merge future updates).

You should take a look at [main.lua](lua/main.lua). There's some stuff here you probably want to change: There's a list of modules imported from CPML and Penlight. There's a section labeled "Suggest you create a namespace for your game here", which you probably want to uncomment, and set up the globals for your own game's namespace there. You also want to change the "defaultApp" variable to point to your main Ent.

Now you'll want to start adding your own .lua files to the project, for your main Ent and any helper stuff your game needs. I use the `app/` directory to store entities that could potentially be run alone as the main Ent; an `ent/` directory to store reusable entities that another Ent might load as a child; the `engine/` directory to store other helper files, and `level/` and `resource/` directories to store my helper files. But you can do it however.

## Using Ents

The first thing to know is Ents are classes, using the Penlight class library (see [here](https://stevedonovan.github.io/Penlight/api/libraries/pl.class.html), or "Simplifying Object-Oriented Programming in Lua" [here](https://stevedonovan.github.io/Penlight/api/manual/01-introduction.md.html)). You probably need to understand what "Classes", "Objects", "Inheritance" and "Instances" are to go any further, and you need to understand the difference between `.` and `:` in Lua.

Entities are instances of `Ent` (or any class inheriting from `Ent`). Every entity keeps a list of child entities. When events occur-- the program boots, there is an update, it is time to draw-- those events are "routed" to every living Ent, starting with the "root" Ent. Some events are:

	* onLoad: Equivalent of lovr.load
	* onUpdate: Equivalent of lovr.update
	* onDraw: Equivalent of lovr.draw
	* onMirror: Equivalent of lovr.mirror

If, say, "onDraw" fires, then for each entity starting with `ent.root` that entity calls its `onDraw()` function (if it has one), and then for each of its children in turn they call their `onDraw()` (if they have one) and repeat with their children. (The children don't get called in any particular order, except for entities that inherit from `OrderedEnt`.) You can route an event to every object yourself by calling `ent.root:route("onEventName", OPTIONALARGS)`, and every loaded entity will get the function call onEventName(OPTIONALARGS). 

So Ents live in a tree of entities. If you've used Unity, Ents are kind of like a combination of Components, gameObjects and scenes. (You can't at the moment give an Ent an inheritable "transform" or world position, but this may appear in a later version of lovr-ent.)

### Command line features

There's a built-in entity (LoaderEnt) that loads and runs Ent classes from disk. The root entity is always LoaderEnt, and it loads the classes you specify in the command line. So if you launch your game by running:

    lovr lovr-ent/lua app/test/testUi

Then lovr-ent will load and run the class in the file "app/test/testUi.lua" (it will `require()` "app/test/testUi", construct the class it returns, and call `insert()`). We can get fancier if we download and add in my other LÖVR helper tool, [Lodr](https://github.com/mcclure/lodr):

    lovr lovr-lodr lovr-ent/lua app/test/cube app/debug/hand app/debug/fps

In this example, lovr loads Lodr, which loads lovr-ent, which loads each of: the "cube" sample app, and two helper apps that respectively display the handset controller in 3D space and display the current FPS in 2D space (in the "mirror" window on your screen). So now you've got the cube running, but with these two nice helpers that let you see the controller and the FPS; and also, because Lodr is watching the files for changes, you can change "cube.lua" and save and any changes will pop on your VR headset in realtime. This is the way I develop my games.

lovr-ent specially processes command line arguments that begin with a `-` or `:`.

* If the very first argument, before anything else, is `--desktop`, lovr-ent will swallow that argument and run in the desktop driver with VR disabled.
* For any other argument, the argument will be recorded and packed into an object named `arg`. When the app ent is constructed, if there are arguments, it will be in a table named `self.arg`. (If there are no arguments this will be nil). You can check for arguments in "onLoad". If you place your arguments after an app name, it will be passed to that app; if you place arguments before (or in place of) an app name, then `defaultApp` will be launched and your arguments will be passed to `defaultApp`. The way these arguments work is:
    * An argument like `:somethingHere` is a *positional* argument: The `:` will be stripped off and added as an integer key to `arg`.
    * An argument like `-something` or `--something` is a flag. `arg` will have the key `something` set to `true`.
    * An argument like `-something=here` or `--something=here` is a keyword argument. `arg` will have the key `something` set to the string "here".

If the command line rules confuse you, you can see them demonstrated by using the test app "app/test/arg".

Note in order for LoaderEnt to load a .lua file, the .lua file needs to return a Ent **class**, like the cube.lua example up there does. LoaderEnt can also load specially formatted .txt files, where each line is one path to something LoaderEnt knows how to load (a class .lua or txt file). If there are no command line arguments, lovr-ent runs the `defaultApp` specified in "main.lua" (which means the defaultApp also has to return an Ent class).

### Ent lifecycle

To create an Ent, you call its constructor; the default constructor for Ents takes a table as argument, and assigns all fields to the entity object. So if you say `YourEnt{speed=3}`, this creates a YourEnt object where `self.speed` is 3 in all methods. Once you've constructed the Ent, you need to insert it to add it to the tree: call `insert( PARENT )` with the . If you don't list a parent the entity will automatically add itself to `ent.root`, but usually Ents will be created by methods of other Ents, so you'll want to set `self` as the parent.

By the way, **the "onLoad" event is special**. It is called not just when `lovr.onLoad()` is called, but also when any object is `insert()`ed to an object which is a child of the root if `lovr.onLoad()` has already been called. This means most of the things you'd normally do in a constructor, like setting default values for variables, it's smarter to do in `onLoad`, since that code will be called only when the object "goes live".

When you're done with an Ent, call `yourEnt:die()`. This registers your Ent to be removed from the tree (which will remove all its children as well) at the end of the current frame. You'll get an "onDie" event call if you or one of your parents gets `die`d, which you can use to do any cleanup.

An interesting thing about the Ent default constructor is that you can do one-off entities by overloading the event methods in the constructor. Here's what I mean:

    Ent{ onUpdate = function(self, dt) print("Updated! dt:" .. dt) end }:insert()

Running this code will create and attach to the root an object that prints the current frame's timestep on every frame.

### Ent routing,  optional fancy stuff

Instead of saying `:route()`, you can instead say `:routeFirstValue()`. In this case, if any function called in the route tree returns a non-nil value, the routing will terminate immediately and the value will be returned to `routeFirstValue`'s caller.

When a function is called as part of a normal `:route()`, that function can return the global value `route_poison` and the routing will halt completely at that moment. No further functions will be called. Alternately, if you return `route_terminate`, routing will continue, but the children of the object that returned `route_terminate` will not be called.

### Ent lifecycle, optional fancy stuff

As above, when an `insert()`ed object becomes "live" (either `lovr.load` is called, or immediately on `insert()` if that's already happened), it gets an "onLoad" event. An object which has had its "onLoad" called has the `ent.loaded` field set.

As above, when you tell an ent to `die()`, it calls "onDie" on itself and its children, then remains in the tree until the end of the current frame. An object which has had its "onDie" called has the `ent.dead` field set.

When the `die()`d, it calls "onBury" on itself and its children, then removes itself from the tree. The garbage collector is now free to reclaim it.

It's nice to perform changes to the tree all at once so an object doesn't accidentally participate in only half of a frame. Toward that end, if you have an object you want to **insert** in the tree but only in the after-period at the end of a frame, you can use:

    queueBirth( someConstructedEnt, someParent )

Or if you just have some general frame cleanup of some sort, you can use

    queueDoom( someFunction )

And someFunction will be called during that same cleanup. Burying, birth and DOOM all occur in the order in which their respective `die()`, `queueBirth()` or `queueDoom()` got called.

### By the way

Although lovr-ent is tied in pretty closely with LÖVR, there's nothing LÖVR-specific about the ent system itself. You could pull "engine/ent.lua" out and use it in a non-LÖVR project, and in fact ent.lua is just a rewrite of similar systems I've previously used in the [Polycode](https://bitbucket.org/runhello/polyconsole) and [UFO](https://bitbucket.org/runhello/ufo/wiki/Home) LUA frameworks.

## Using namespaces

If you want to understand the namespace feature, [it has its documentation on a separate page](https://bitbucket.org/runhello/namespace.lua).

But, the short version is: Normally in a Lua program every file has the same globals table. But if you put `namespace "somename"` at the top of your file, globals in that file will be shared only between other `namespace "somename"` files.

The way I recommend using this is, look for the "create a namespace for your game here" comment in main.lua. Delete that, insert `namespace("mygamename", "standard")`, and then assign any globals you want in your program. Then put `namespace "mygamename"` at the top of all your game's source files.

("standard" is the namespace that's used by lovr-ent itself. You want your namespace to inherit from "standard" so it's got all the lovr-ent stuff in it.)

## lovr-ent globals

There's several files in lovr-ent which contain miscellaneous utilities and which are included into the "standard" namespace by default. These global symbols are listed below; you can find more detailed comments for some of them in the linked files:

In [types.lua](lua/engine/types.lua):

* `pull(dst, src)` - copy all the fields from one object into another
* `pullNamed(keys, dst, src)` - simulate keyword arguments (see comment in "types.lua")
* `ipull(dst, src)` - append all numeric fields from src onto the end of dst
* `tableInvert(t)` - takes a table and returns a new table with keys and values swapped
* `tableMerge(a, b)` - given two tables, return a new table with all the key/value pairs from both
* `tableConcat(a, b)` - given two lists, return a new table with all the numeric fields from both appended
* `tableSkim(t, keys)` - given a table and a list of keys, return a new table picking only the key/value pairs whose keys are in the list
* `tableSkimErase(t, keys)` - same but erases the keys from a
* `tableSkimUnpack(t, keys)` - given a table and a list of keys, return the unpacked values corresponding to the requested keys in order
* `tableSkimNumeric(t)` - Extract just the numeric fields of a table into a new table
* `tableTrue(t)` - true if table is nonempty
* `tableCount(t)` - given a table returns the number of key/value pairs in it (including non-numeric keys)
* `tableKeys(t)` - given a table returns a list containing its keys
* `toboolean(v)` - converts value to true (if truthy) or false (if falsy)
* `ipairsReverse(t)` - same as ipairs() but iterates keys in descending order
* `ipairsOrSingle(v) - acts like ipairs, but if given a non-table value (like a number) iterates over an implied list containing just that value
* `ipairsIf` - acts like ipairs, but if given nil does nothing
* `ichars(str)` - like ipairs() but iterates over characters in a string
* `mapRange(count, f)` - returns table mapping f over the integer range 1..count
* `classNamed(name, parent)` - like calling Penlight `class()`, but sets the name
* `stringTag(str, tag)` - Trivial function which returns "str-tag" if tag is non-nil and str if tag is nil.
* `lovrRequire(module)` - Helper for use in threads where lovr modules may not be loaded, call with for example argument `"thread"` to load lovr.thread 
* A queue class
* A stack class

In [loc.lua](lua/engine/loc.lua):

* "Loc", a rigid body transform class (see loc.lua, where its methods are documented in comments, or app/test/loc.lua for a demonstration). A Loc is a triplet of a position, rotation and scale. Locs can be composed and applied to vectors, like a mat4 (when applied to a vector the vector is scaled, then rotated, then translated).

In [lovr.lua](lua/engine/types.lua):

* `unpackPose(controllerName)` - Given a controller name, returns a (vec3 at, quaternion rotation) pair describing its pose
* `offsetLine(at, q, offset)` and `forwardLine(at,q)` - Takes the pair returned from `unpackPose` and either maps a vector into its pose's reference frame, or returns an arbitrary point the controller is "pointing at".
* `primaryTouched(controllerName)`, `primaryDown(controllerName)`, `primaryAxis(controllerName)` - Equivalents of `lovr.headset` `isTouched`, `isDown` and `axis` but for whatever the appropriate "primary" thumb direction is on that device
* Adds a `loc:push()` to Loc that `lovr.graphics.push()`es a Loc's transform

In [ugly.lua](lua/engine/ugly.lua):

* `ugly` works exactly the same as the Penlight `pretty` class (it is a fork of `pretty`) but it shows only one layer of keys and values instead of recursing.

## How to use modelView

If you launch lovr-ent with the argument `app/debug/modelView`, like:

    lovr lovr-ent/lua app/debug/modelView

This will launch an app that searches the entire Lovr filesystem, lists all .gltf, .glb or .obj files it finds, and once you have selected one displays it, slowly rotating, with your choice of shaders.

Clicking the Standard... button will allow you to adjust the shader properties, and clicking Edit... will allow you to view or alter (but not save back) some properties of the animations, materials, and skeleton nodes in the model. Some additional information will be printed to STDOUT in these panes.

## How to use the UI2 library

When you run LÖVR on a desktop computer, it displays a "mirror" window showing a copy of what's in the headset. There's a special callback, which in lovr-ent becomes the `onMirror` event, that lets you draw things just into this mirror window. I think this is a great place to draw 2D interfaces for debugging, level editor type things, etc.

Because the 2D UI parts of this library are intended for developer tools, not end user interfaces, they are all pretty simplistic.

### Modes and "flat"

Normally, when `onMirror` gets called, the camera is still set up for 3D drawing. If you call

    `uiMode()`

as the first line of your onMirror, it will set up a reasonable 2D orthographic camera (top of screen is y=1, bottom is y=-1, left side is -aspect and right side is +aspect where "aspect" is the window width divided by its height.

There's a convenient table in `engine/flat.lua` (see the [comments](lua/engine/flat.lua) in that file):

    local flat = require "engine.flat"

...containing the metrics of the mirror window and a mirror-appropriate font.

### UI2

Lovr-ent also comes with a file full of Ents that act as simple UI elements:

    local ui2 = require "ent.ui2"

At the moment, it contains labels and buttons and there's an auto-layout class that sticks all the elements in the corner one after the other. This is mostly documented [in the file](lua/ent/ui/init.lua), but the best way to understand it is to just read [the example program](lua/app/test/testUi.lua). It's all hopefully obvious from the examples. (There is also a [grid example program](lua/app/test/testGridUi.lua) demonstrating the grid layout type.)

### UI2: The nonobvious parts

In order for mice to work, you must call `ui2.routeMouse()` at least once during your program startup. A simple way to do this is to have your app ent inherit from `ScreenEnt` and call `ui2.ScreenEnt.onLoad(self)` on the first line of your `onLoad` (if you have one).

When you create a layout manager object, one of the allowed constructor parameters is `pass=sometable`. When the layout manager does layout, for each object it lays out, it will take every field in `sometable` and set those same fields on the table. If you want, in an Ent subclass you make, to do something with the passed parameters other than just setting them, overload `layoutPass()`.

There's a class in `ui2` named `SwapEnt`. This class adds one additional helper method to Ent, `swap(otherEnt)`. (`ScreenEnt` inherits from `SwapEnt`, so if you inherited from `ScreenEnt`, you have this method). This method causes the `swap()`ed ent to `die()`, then queue `otherEnt` for birth on the next frame. What is this for? Well, probably, if you're making debug/test UI screens, you won't have just one UI screen. You probably have several screens and some kind of top level main menu linking them all. So when you write the Ent that allocates and lays out all your ButtonEnts, have it inherit from `SwapEnt`, and then you can easily swap to another screen by creating it and calling `Swap{}` or just close by calling `swap()` with nil. (The modelView app is a good example of how to build a multiscreen application this way.)

Layout may take a constructor field named "mutable". Set this to true for layouts that you expect to change sometimes (IE, there is a button whose label might change after onLoad, changing the button's size). This field changes a few things: UiEnts in a mutable layout are allowed to have nil labels (though full layout will not occur while at least one UiEnt in the layout has a nil label); and UiEnts in a muable layer will be given a `self:relayout()` method which they should call on themselves when they know their size has changed. In both mutable and non-mutable layouts, you may call `:layout(true)` on a layout to force a re-layout of all buttons (potentially resizing in the process). There is an example of using this in my [Lovr MIDI project](https://github.com/mcclure/lovr/tree/ZP_midi).

### UI3

UI2 draws in the mirror window, but there is an experimental feature for drawing UI2 layouts in 3D, in VR. Controls are selected with the VR handsets, and if you "mouse over" (point at) one of the buttons with the handset a line and highlight will be drawn. This feature ("UI3") also has [an example program](lua/app/test/testUi3.lua), but the interface to UI3 has not yet been fully developed and so this it is a little less obvious how to use it.

The short version is

* The root ScreenEnt of your app should call `ui3.loadSurfaceAndHand(self, force2d)` (where `force2d` is optional, see below).
* When you create a layout, don't construct the object yourself; instead call `ui3.makeLayout(self.surface3, ui2.PileLayout, {*whatever args here*})`, where `self.surface3` is populated by `loadSurfaceAndHand` (so you do have to call that *first*), `ui2.PileLayout` may be replaced with the layout class of your choice, and the table is the arguments you would have passed to the layout class constructor.
* If you create a slider or slider triplet, don't construct the object yourself, instead call `ui3.makeSliderEnt({*whatever args here*}, force2d)` where the table is the arguments to the slider class constructor and `force2d` is the optional argument explained below. (Objects other than sliders will just work.)

Most of the quirkiness of the ui3 comes from `force2d`, a feature shared by pretty much all ui3 code. The idea here is that if you are building a debug ui, then *probably* you want to draw the interface in 2D in the mirror if you're using the desktop driver and in 3D in the game world if you're using a VR driver. So if this is what you want:

- Set `force2d` to `lovr.headset.getDriver() == "desktop"` (or whatever logic you want) when you call `loadSurfaceAndHand` and `makeSliderEnt`, and they will do the right thing. If `ui3.makeLayout` receives `nil` for its surface3 argument it will create a normal 2D layout and things will just work.
- If you want to have multiple planes with UI on them, there is a special "split-screen" container class `split3.makeSplitScreen` which is demonstrated in the [example program](lua/app/test/testUi3.lua). It takes a series of ScreenEnt objects as "pages", and has a force2d argument. In 3D, the pages will be distributed evenly around the VR environment, and in 2D, the pages will run fullscreen with arrows on the sides to switch between them. Note: Objects passed to makeSplitScreen don't need to call `loadSurfaceAndHand`.

If you don't want to do dual-mode 2D/3D, you *just* want a menu in 3D, then:

- Leave out the force2D argument and the ui3 classes will create 3D objects only.
- If you want multiple UI planes, you can use `split3.makeSplitScreen` if you want, or just create multiple ScreenEnts that each call `loadSurfaceAndHand` and set a Loc value `self.surface3.transform` for each to position it.

This will be improved later.

## Debug ents

The "apps" [app/debug/hand](lua/app/debug/hand.lua) and [app/debug/fps](lua/app/debug/fps.lua), described above in the LoaderEnt doc, can also be `require`d and inserted as child Ents in the `onLoad` of an Ent you define. In addition, there are a couple included ents which are nice for debug purposes:

### Floor

[ent/debug/floor](lua/ent/debug/floor.lua) draws a placeholder checkerboard floor. That's it. There's some simulated fog. You can set a physical size (`floorSize`) and a checkerboard density (`floorPixels`) in the constructor.

### DebugCubes

[ent/debug/floor](lua/ent/debug/debugCubes.lua) is an Ent with fairly complex options (see comments in file) that draws temporary cubes. For example imagine your app declares `self.debugCubes = (require "ent.debug.debugCubes")():insert()`. You could then at some later point call:

    self.debugCubes:add( vec3(2,1,1) )

This call will cause a cube to be drawn at coordinate (2, 1, 1) for the next 1 second. This can be useful for visualizing game logic that takes place in space; say you have 3D objects moving around, and when they collide you drop a debug cube at the collision point.

Instead of a vector you can give it a table describing specific properties of the cube:

	self.debugCubes:add( {at=vec3(2,1,1), color={1,0,0}, lineTo=vec3(1,0,0), lineColor={0,0,0}}, 0.5, true )

This will draw a red cube at (2, 1, 1), with a black line from its center to (1, 0, 0). The second argument causes the draw time to be half a second instead of the default 1. Passing true for the third argument causes the cube and line to be drawn "on top" of everything else (ie with depth test off).

The exact keys accepted in the cube table are described in the comment in the source file, but especially noteworthy options are:

- Passing false for the duration causes the cube to never expire (draw forever)
- Passing true for the duration causes the cube to draw for one frame and then expire immediately (useful if, for exmaple, you call this add() in your `onUpdate` every frame)
- Passing a `noCube=true` key in your cube description table causes it to draw no cube, only a line.

Setting `onTop=true` in the DebugCubes constructor causes the cubes to always be drawn on top regardles of the third arguemnt.

## Thread helpers

The [engine/thread](lua/engine/thread) directory contains helpers for writing code that use Lovr threads. There is a flag `local singleThread = false` at the top of [main.lua](lua/main.lua); set this to true and the included thread tools (well, thread tool; see "Loader" below) will degrade gracefully to a single-threaded mode.

I don't yet have documentation for the thread classes, however, there is a sample program app.test.thread; see the comments on the functions in the app/test/thread directory to see how doing threads the lovr-ent way works. 

### Loader

The one finished thread utility is a loader class. `require` [engine.thread.loader](lua/engine/thread/loader.lua) and call Loader() to create a loader object:

    self.textureData = Loader("textureData", "path/to/an/image.png")

The moment this loader object is constructed, it will start loading image.png from disk and decoding it into a Lovr TextureData object. Later, when you need to use the TextureData object, call `self.textureData:get()`; if the TextureData has finished loading it will return it, otherwise it will block until loading finishes and then return it. The first argument determines what kind of data to load; the two currently recognized keys are "modelData" and "textureData". If you want to add more load types, edit [engine/thread/action/loader.lua](engine/thread/action/loader.lua).

There are optional third and fourth arguments to the Loader constructor. The third argument is a "filter" function which is executed on the main thread on the loaded value as soon as the value is received from the helper thread; the fourth is the name of the loader thread to use (there can be more than one at once). So for example you could say:

	self.texture = Loader("textureData", "path/to/texture.png", Loader.dataToTexture) 
	self.model = Loader("modelData", "model/RemoteControl_L.glb", Loader.dataToModel, "model")

You probably don't want a TextureData or a ModelData; you want a Texture or a Model. Unfortunately right now in Lovr Textures and Models can only be created on the main thread, so the built-in `Loader.dataToTexture` and `Loader.dataToModel` filters do that conversion for you so when you later call `self.texture:get()` you know it will return a texture. In this example the texture is loaded on the default loader thread and the model is loaded on a second loader thread identified by the key "model".

As a very minor optimization, there's a `connect` method on the Loader class which can be used to kick off loader threads before you actually construct any Loader objects. For example I like to include the Loader class like this:

    local Loader = require "engine.thread.loader"
    Loader:connect()
    Loader:connect("model")

The loader threads take a **little** bit of time to run their init code, so calling `connect` early means that init code will start as soon as you've required loader.lua instead of waiting until you first initialize a Loader object.
