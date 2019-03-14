/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System;
using System.Runtime.InteropServices;
using UnityEngine;

namespace Arm
{
    public class Annotations
    {
        // Maintain global UID for each Custom Activity Map.
        private static UInt32 globalCamView = 1;

        // Global state as to whether annotatations are available for use.
        // We start in Uninitialised, and attempt to activate on first use.
        private enum AnnotationState { Uninitialised, Active, Inactive };
        private static AnnotationState state = AnnotationState.Uninitialised;

#if UNITY_ANDROID
        [DllImport("__Internal")]
        private static extern void gator_annotate_setup();

        [DllImport("__Internal")]
        private static extern void gator_annotate_marker(string str);

        [DllImport("__Internal")]
        private static extern void gator_annotate_marker_color(UInt32 color, string str);

        [DllImport("__Internal")]
        private static extern void gator_annotate_color(UInt32 channel, UInt32 color, string str);

        [DllImport("__Internal")]
        private static extern void gator_annotate_str(UInt32 channel, string str);

        [DllImport("__Internal")]
        private static extern void gator_annotate_name_channel(UInt32 channel, UInt32 group, string str);

        [DllImport("__Internal")]
        private static extern void gator_cam_view_name(UInt32 view_uid, string name);

        [DllImport("__Internal")]
        private static extern void gator_cam_track(UInt32 view_uid, UInt32 track_uid, UInt32 parent_track, string name);

        [DllImport("__Internal")]
        private static extern UInt64 gator_get_time();

        [DllImport("__Internal")]
        private static extern void gator_cam_job_start(UInt32 view_uid, UInt32 job_uid, string name, UInt32 track, UInt64 time, UInt32 color);

        [DllImport("__Internal")]
        private static extern void gator_cam_job_stop(UInt32 view_uid, UInt32 job_uid, UInt64 time);

        [DllImport("__Internal")]
        private static extern void gator_cam_job(UInt32 view_uid, UInt32 job_uid, string name, UInt32 track, UInt64 startTime, UInt64 duration, UInt32 color, UInt32 primaryDependency, IntPtr dependencyCount, IntPtr dependencies);
#endif

        /*
         * Converts a Unity Color into a 32-bit Int used by gator to represent
         * the color.  Gator's format is little-endian with a 0x1b escape code.
         */        
        private static UInt32 colorToGatorInt(Color color)
        {
            UInt32 colorInt = ((uint)(color.b * 255f) << 24) +
                             ((uint)(color.g * 255f) << 16) +
                             ((uint)(color.r * 255f) << 8) +
                             ((uint)0x1b);

            return colorInt;
        }

        public static void runTests()
        {
            Debug.Assert(colorToGatorInt(Color.blue) == 0xff00001b);
            Debug.Assert(colorToGatorInt(Color.green) == 0x00ff001b);
            Debug.Assert(colorToGatorInt(Color.red) == 0x0000ff1b);

        }

        /*
         * Returns true if annotations are supported (we are running on Android
         * and successfully initiatised the library, false otherwise
         */
        private static bool canDoAnnotations()
        {

#if UNITY_ANDROID
            if (state == AnnotationState.Uninitialised)
            {
                try
                {
                    gator_annotate_setup();
                    state = AnnotationState.Active;
                    return true;
                }
                catch (System.EntryPointNotFoundException)
                {
                    state = AnnotationState.Inactive;
                    return false;
                }
            }

#else
            state = AnnotationState.Inactive;
#endif
            return (state == AnnotationState.Active);
        }

        /*
         * Emit a simple marker that is displayed along the top of Streamline's
         * timeline.
         */        
        public static void marker(string str)
        {
#if UNITY_ANDROID
            if (canDoAnnotations())
            {
                gator_annotate_marker(str);
            }
#endif
        }

        /*
         * Emit a colored marker that is displayed along the top of Streamline's
         * timeline.
         */        
        public static void marker(string str, Color color)
        {
#if UNITY_ANDROID
            if (canDoAnnotations())
            {
                UInt32 col = colorToGatorInt(color);
                gator_annotate_marker_color(col, str);
            }
#endif
        }

        /*
         * Return a timestamp in a format that can later be used to register
         * a job on a Custom Activity Map's Track.
         */        
        public static UInt64 getTime()
        {
#if UNITY_ANDROID
            if (canDoAnnotations())
            {
                return gator_get_time();
            }
#endif
            return 0;
        }

        /*
         * Represents a channel of activity for the thread in which the channel
         * was created.  Displayed as a row in Streamline's Heat Map view,
         * inside the process.
         */
        public class Channel
        {
            // Maintain a unique ID for each channel.
            static UInt32 channelCount = 0;

            // Our channel ID.
            UInt32 channel;

            /*
             * Specify a name, which will be displayed in Streamline's Heat
             * Map view.
             */            
            public Channel(string name)
            {
                channelCount++;
                channel = channelCount;

#if UNITY_ANDROID
                if (canDoAnnotations())
                {
                    gator_annotate_name_channel(channel, 0, name);
                }
#endif
            }

            /*
             * Starts an annotation in the channel, which will be labelled as
             * specified.  This will appear in the Channel as an activity that
             * begins at the point in time where this method was called.  It
             * will end when the next annotate() call is made, or the next end()
             * call.
             */
            public void annotate(String str)
            {
#if UNITY_ANDROID
                if (canDoAnnotations())
                {
                    gator_annotate_str(channel, str);
                }
#endif
            }

            /*
             * As above, but with a specific colour.           
             */
            public void annotate(String str, Color color)
            {
                UInt32 intColor = colorToGatorInt(color);
#if UNITY_ANDROID
                if (canDoAnnotations())
                {
                    gator_annotate_color(channel, intColor, str);
                }
#endif
            }

            /*
             * Marks the end of an annotation.  The other way to end an
             * annotation is to start a new one in the channel.
             */
            public void end()
            {
#if UNITY_ANDROID
                if (canDoAnnotations())
                {
                    gator_annotate_str(channel, null);
                }
#endif
            }
        }

        /*
         * Custom Activity Maps (CAMs) are each special views, displayed in the
         * bottom half of the Streamline UI.  Each CAM consists of several
         * Tracks, and each Track can have Jobs placed on it (like annotations
         * in channels, but more flexible).
         */        
        public class CAM
        {
            /*
             * Represents a Track within a CAM           
             */
            public interface CAMTrack
            {
                /*
                 * Creates a CAMJob object, which will mark itself as starting
                 * immediately.  Mark completion with a call to stop() on the
                 * resulting CAMJob.                
                 */
                CAMJob makeJob(string _name, Color color);

                /*
                 * Register a job with the specified start and stop times.  This
                 * is useful if you are unable to register jobs as they happen,
                 * for example when they are created as part of a job running in
                 * the Unity Job Scheduler.
                 */
                void registerJob(string name, Color color, UInt64 startTime, UInt64 stopTime);
            }

            /*
             * Represents a Job within a Track in a CAM.
             */
            public interface CAMJob
            {
                /*
                 * Registers that a job has completed at this point in time.
                 */
                void stop();
            }

            private UInt32 trackCount;
            private UInt32 jobCount;
            private UInt32 viewUid;

            /*
             * When creating a Custom Activity Map, you must specify a name,
             * which is used to name the view in the Streamline UI.
             */            
            public CAM(string name)
            {
                // Tracks and Jobs need unique IDs.
                this.trackCount = 0;
                this.jobCount = 0;

                // Each CAM needs a unuque ID.
                this.viewUid = globalCamView++;

#if UNITY_ANDROID
                if (canDoAnnotations())
                {
                    gator_cam_view_name(this.viewUid, name);
                }
#endif
            }

            /*
             * Creates a track with the specified name.  This can then be used
             * to register Jobs.  Each Track appears as a named row in the
             * parent CAM.
             */
            public CAMTrack createTrack(string _name)
            {
                return new CAMTrackImp(this, _name, ++trackCount);
            }

            /*
             * Private implementation of the CAMTrack.
             */            
            private class CAMTrackImp : CAMTrack
            {
                // Parent CAM - needed because Jobs must reference the CAM ID.
                private CAM parent;

                // Maintain unique UIDs for each Track.
                private UInt32 trackUid;

                /*
                 * Each Track just needs a name - the rest is maintained
                 * automatically by the parent CAM.
                 */
                public CAMTrackImp(CAM parent, String name, UInt32 trackUid)
                {
                    this.parent = parent;
                    this.trackUid = trackUid;

#if UNITY_ANDROID
                    if (canDoAnnotations())
                    {
                        gator_cam_track(parent.viewUid, this.trackUid, 0xffffffff, name);
                    }
#endif
                }

                /*
                 * Creates a CAMJob object, which will mark itself as starting
                 * immediately.  Mark completion with a call to stop() on the
                 * resulting CAMJob.                
                 */
                public CAMJob makeJob(string _name, Color color)
                {
                    UInt32 intColor = colorToGatorInt(color);

                    return new CAMJobImp(parent, trackUid, parent.jobCount++, _name, intColor);
                }

                /*
                 * Register a job with the specified start and stop times.  This
                 * is useful if you are unable to register jobs as they happen,
                 * for example when they are created as part of a job running in
                 * the Unity Job Scheduler.
                 */
                public void registerJob(string name, Color color, UInt64 startTime, UInt64 stopTime)
                {
                    UInt32 intColor = colorToGatorInt(color);
                    UInt32 jobUid = parent.jobCount++;
#if UNITY_ANDROID
                    if (canDoAnnotations())
                    {
                        gator_cam_job(parent.viewUid, jobUid, name, trackUid, startTime, stopTime - startTime, 0x00ffff1b, 0xffffffff, new System.IntPtr(0), new System.IntPtr(0));
                    }
#endif
                }
            }

            /*
             * Private implementation of the CAMJob.
             */
            private class CAMJobImp : CAMJob
            {
                // These are all maintained by the CAM and the Track.
                private UInt32 viewUid;
                private UInt32 jobUid;
                private UInt32 trackUid;

                /*
                 * Retrieves the existing time and uses it to register the start
                 * of a job.  Finish it with a call to stop().  If you want to
                 * register a job after the fact, use Track.registerJob() to
                 * register a Job with a specific start and end time.
                 */
                public CAMJobImp(CAM parent, UInt32 trackUid, UInt32 jobUid, string name, UInt32 color)
                {
                    this.viewUid = parent.viewUid;
                    this.jobUid = jobUid;
                    this.trackUid = trackUid;
#if UNITY_ANDROID
                    if (canDoAnnotations())
                    {
                        UInt64 startTime = gator_get_time();
                        gator_cam_job_start(this.viewUid, this.jobUid, name, this.trackUid, startTime, color);
                    }
#endif
                }

                /*
                 * Marks the end of a Job, using the current time as the end
                 * time. If you want to register a job after the fact, use
                 * Track.registerJob() to register a Job with a specific start
                 * and end time.                
                 */
                public void stop()
                {
#if UNITY_ANDROID
                    if (canDoAnnotations())
                    {
                        UInt64 stopTime = gator_get_time();
                        gator_cam_job_stop(this.viewUid, this.jobUid, stopTime);
                    }
#endif
                }
            }
        }
    }
}
