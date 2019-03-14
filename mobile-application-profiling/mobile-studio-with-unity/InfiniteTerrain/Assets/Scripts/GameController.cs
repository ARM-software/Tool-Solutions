/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

/**
 * Singleton object for the whole game (persists across scene changes)
 * Controls the scene changes and manages other persistent state.
 **/
public class GameController : MonoBehaviour {

    // The Streamline channel used to register scene changes.
    private Arm.Annotations.Channel sceneChannel;

    // The Streamline channel used to register TerrainController activity.
    public Arm.Annotations.Channel terrainControllerChannel;

    // The CustomActivityMap for the scheduled Terrain Jobs.  We have an array
    // of tracks that we pick from to make it easier to see when parallel Jobs
    // are running.
    public Arm.Annotations.CAM terrainCAM;
    public Arm.Annotations.CAM.CAMTrack[] terrainTracks;

    // List of scene names - we loop through all of these
    public string[] sceneList;

    // Time between scene changes, in seconds.
    public float sceneChangeTime = 20f;

    // The initil scene in the sceneList to display.
    private int currentScene = 0;

    void Start () {
        // Persist across scene changes
        DontDestroyOnLoad(this);

        // Configure Channels for Arm annotations.
        sceneChannel = new Arm.Annotations.Channel("Scene");
        terrainControllerChannel = new Arm.Annotations.Channel("TerrainController");

        // Configure the Custom Activity Map for Terrain Job activity
        terrainCAM = new Arm.Annotations.CAM("Terrain Generation");

        terrainTracks = new Arm.Annotations.CAM.CAMTrack[16];
        for (int i = 0; i < 16; i++)
        {
            terrainTracks[i] = terrainCAM.createTrack("TerrainJob");
        }

        // Kick off the first scene.
        SceneManager.LoadScene(sceneList[currentScene]);
        Invoke("ChangeScene", sceneChangeTime);
    }

    // This is called at the start of each new scene, specifying details of the
    // annotation to emit.
    public void registerScene(string scene, Color color)
    {
        sceneChannel.annotate(scene, color);
    }

    // Generate the per-frame marker.
    void Update () {
        Arm.Annotations.marker("Frame " + Time.frameCount, Color.green);
    }

    // Move to the new scene.
    void ChangeScene()
    {
        currentScene = (currentScene + 1) % sceneList.Length;
        SceneManager.LoadScene(sceneList[currentScene]);
        Invoke("ChangeScene", sceneChangeTime);
    }
}