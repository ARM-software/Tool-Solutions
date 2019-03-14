Unity Bindings for Arm Mobile Studio with Demo
==============================================
Copyright (c) 2019 Arm Limited. All rights reserved.

This is the source code for the  *InfiniteTerrain* demo used to show how
to integrate [Arm Mobile Studio's](https://developer.arm.com/mobile-studio) Streamline Annotations with your Unity Project.

It goes with the blog [Better Together: Integrating Arm Mobile Studio with Unity](https://community.arm.com/).

The InfiniteTerrain Unity Project was developed and tested with Unity 2018.2.
If you open the project in Unity, you will get fully-working content that is
configured to produce a 64-bit Android Development Build, using the IL2CPP
scripting backend, as described in the blog.

For convenience, two binary packages have been produced from the source:

## ArmMobileStudio.unitypackage
This is a package export of the *Plugins* and *Arm Mobile Studio* folders.  If
you add this package to your existing Unity Project, you will have everything
that you need to start using Streamline Annotations.  The *README.md* file in
the *Arm Mobile Studio* folder contains the API documentation.

## InfiniteTerrain.apk
This is a 64-bit APK, ready to be deployed onto an Android platform.  It is a
development build with full support for Streamline Annotations.  You can
reproduce this binary simply by performing a project build with the existing
settings.

## Further Reading
If you'd like to know more or raise any questions, please check out the [Arm
Mobile Studio developer pages](https://developer.arm.com/mobile-studio).

Community support is available from [Arm's Graphics and Multimedia forum](https://community.arm.com/developer/tools-software/graphics/f/discussions).
