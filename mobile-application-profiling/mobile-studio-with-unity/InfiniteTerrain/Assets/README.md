InfiniteTerrain Unity Project
=============================
Copyright (c) 2019 Arm Limited. All rights reserved.

This is a sample Unity project that demonstrates integration with the Streamline
component of Arm Mobile Studio.  It is a companion project to this Arm blog
post:

<link>

It has been tested with Arm Mobile Studio 2019.0 and Unity 2018.2.  You can
download the free Starter Edition of Arm Mobile Studio here:

https://developer.arm.com/mobile-studio/downloads

Behaviour
---------
This project is a flythrough of a procedurally generated terrain.  The camera
twists and turns, with new terrain tiles generated on-the-fly as they are
needed.  Tiles that get too far away from the camera are deleted, so the
complexity of the scene remains roughly the same over time, once the scene is
filled out.  Sometimes the camera moves slowly, so the rate of new terrain
generation is very slow, then it speeds up, so the rate of terrain generation
needs to increase.  The edges of each tile are rendered in a darker colour, so
you can see the size of each tile.

The intention is to demonstrate how different configurations of Terrain tile
sizes and the level of parallelism used during terrain generation affect
performance and resource utilisation.  To this end, the project consists of four
scenes, all of which provide an identical visual experience but configure the
TerrainController object differently, causing terrain generation to be performed
in different ways. The scenes cycle automatically every 30 seconds.

The Arm Mobile Studio API
-------------------------
The *Arm Mobile Studio* folder contains its own README.md that describes the API
for the Streamline Annotations capability.  The project uses this API to allow
Streamline to visualise what's going on when terrain is generated. 

The *Plugins/Android* folder contains the C source code that implements the
protocol used to communicate annotations from Unity back to Streamline.  Unity
will automatically compile this code and include it in Android builds.

These two parts are available separately as a Unity Package, which you can add
to your own projects.  You can download it here:



Project Structure
-----------------
The *Materials*, *Shaders* and *Textures* folders are there to support the look
of the terrain, and are generally uninteresting.

The *Scenes* folder contains the four main scenes, and also an initial
("Startup") scene.  The Startup Scene exists because we need to instantiate a
GameController object that persists across all scenes.

The *Scripts* folder is where all the fun is.  The files are as follows:

### GameController
This object is instantiated in the Startup scene and persists across the whole
run of the application.  It is responsible for:
- Creating some initial structure to support the Streamline annotations capability
- Emitting Streamline markers for every frame
- Switching between scenes
- Providing an API for each Scene to emit a Streamline annotation that indicates the start of a new scene.

### Player
- Represents the invisible 'player' that the camera tracks around the scene.
- Some vaguely configurable math that moves the player around the scene,
  speeding up and slowing down as it goes.

### Camera
- Some logic to smoothly track the player as it moves around the scene.

### SceneController
- Simple container for scene-specific properties, so we can emit a Streamline Annotation to indicate which scene we're currently rendering.

### TerrainController
- One of the only really serious bits of code.  Schedules terrain generation based on the location of the player in the scene.  The actual work to calculate the shape of the terrain is performed by TerrainJob objects, which run as part of the Unity Job Scheduler.
- Creates new Mesh object for those terrains once the TerrainJobs have completed.
- Generates the text on the GUI that shows details of the current scene and how many terrain generations are currently running.

### TerrainJob
- Runs as part of the Unity Job Scheduler, created by the TerrainController.
- Contains the work to generate the vertices and triangles for the terrain meshes.
	
Further Reading
---------------

If you'd like to know more or raise any questions, please check out the Arm
Mobile Studio developer pages at:

https://developer.arm.com/mobile-studio

Community support is available from Arm's Graphics and Multimedia forum:
https://community.arm.com/developer/tools-software/graphics/f/discussions

