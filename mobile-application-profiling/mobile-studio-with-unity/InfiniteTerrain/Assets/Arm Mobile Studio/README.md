Unity Bindings for Arm Mobile Studio
====================================
Copyright (c) 2019 Arm Limited. All rights reserved.

Introduction
------------
These are the C# bindings for Arm Mobile Studio's Streamline component.  They
are a companion project to this [Arm blog post](https://community.arm.com).


Arm Mobile Studio includes a component called *Streamline*, which can collect
and present hardware performance counters from Android devices.  It has an
*annotations* feature, which allows the application being profiled to emit
additional information, which Streamline will display alongside the captured
performance counter information.  See the blog post above for plenty of
examples of it in action.

This package has been tested with Arm Mobile Studio 2019.0 and Unity 2018.2.
You can download the free [Starter Edition of Arm Mobile Studio](https://developer.arm.com/mobile-studio/downloads) and try it out.


The remainder of this file presents examples of the annotations in use.  See
the source code for more details of the internal implementation.

Usage
-----

### Markers
The simplest annotations are markers.  To use them in a project into which you
have included this package, simply call into the Arm library as follows:

    Arm.Annotations.marker("Frame");
  
This will emit a timestamped marker with the label "Frame", which Streamline
will show along the top of the timeline.

You can also specify the color of the marker by passing an optional Color
object, such as:

    Arm.Annotations.marker("Frame", Color.green);
  
### Channels
Channels are custom event timelines associated with a thread.  Once a channel
has been created, you can place annotations within it.  Like a Marker, an
annotation has a text label and a color, but unlike Markers they span a range
of time.  Channels appear in the Heat Map view, next to the thread in which they
were created.

Creating a channel is simple enough:

    channel = new Arm.Annotations.Channel("AI");
 
Annotations can be inserted into a channel easily:

    channel.annotate("NPC AI", Color.red);
 
    // ...do work...
 
    channel.end();
  
### Custom Activity Maps
Custom Acitvity Maps (CAMs) are a global (not per-thread) set of timelines.
Each CAM appears as its own view in the lower half of Streamline's UI, so each
CAM has a name, and consists of several Tracks, each of which appears as a named
row in the CAM.  Activity is logged into a Track by registering Jobs into it.

Creating a CAM is straightforward:

    gameCAM = new Arm.Annotations.CustomActivityMap("Game Activity");
 
...as is adding Tracks to the CAM:
 
    aiTrack = gameCAM.createTrack("AI Activity");
    terrainTrack = gameCAM.createTrack("Terrain Generation Activity");
    windTrack = gameCAM.createTrack("Wind Activity");

Once those are created, there are two ways to register a Job within a track. The
first is to create the Job just as you start to undertake the activity you want
to associate with it, and end the Job when you are done, like you did with
Annotations:

    job = aiTrack.makeJob("NPC AI", Color.blue);
 
    // ...do work...
  
    job.end();
 
The other method is to store the start and end times of your work, and then
later add them to the Track:

    UInt64 startTime = Arm.Annotations.getTime();

    // ...do work...

    UInt64 endTime = Arm.Annotations.getTime();
 
    aiTrack.registerJob("NPC AI", Color.blue, startTime, endTime);
 
The advantage of this second approach is that the getTime() method is very
cheap, and can also be safely invoked from jobs running within the Unity Job
Scheduler. 

Further Reading
---------------

If you'd like to know more or raise any questions, please check out the [Arm
Mobile Studio developer pages](https://developer.arm.com/mobile-studio).

Community support is available from [Arm's Graphics and Multimedia forum](https://community.arm.com/developer/tools-software/graphics/f/discussions).

