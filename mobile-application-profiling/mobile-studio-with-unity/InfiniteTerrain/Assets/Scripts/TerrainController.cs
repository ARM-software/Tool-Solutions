/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Collections;
using Unity.Jobs;
using System;

/**
 * Initiates the generation of new terrain geometry using the Unity Job Scheduler,
 * and processes those Jobs into new meshes in the scene once they complete.
 * 
 * 
 **/

public class TerrainController : MonoBehaviour
{
    // The player to follow.  We track this so we know when to destroy terrains
    // that are too far away, and when to create new ones.
    public GameObject player;

    // The number of meshes away from the player to generate.
    public int renderDistance = 2;

    // Dimensions of a given mesh, we tile the world with these.
    public Vector3 worldDimensions;

    // The number of X and Z points within that mesh.
    public Vector2Int resolution;

    // Scale to apply to heightfield generation
    public float landscapeScale = 0.1f;

    // Scale to apply to grass/sand generaton
    public float terrainScale = 0.1f;

    // Offset applied to the height function.
    public float landscapeSeed = 100f;

    // Offset applied to the grass/sand function.
    public float terrainSeed = 200f;

    // The height of the water in the scene.
    public float waterLevel = 0.15f; // The point where the terrain flattens to water
    public float waterSpace = 0.2f;  // The height of the actual water mesh above waterLevel.

    // The materials used to texture the scene.  These are copied into the
    // sharedMaterials array on startup, so they are not modified at play time.
    public Material grassMaterial;
    public Material sandMaterial;
    public Material waterMaterial;

    // The maximum number of terrains that we will schedule for generation at
    // any time.  If we hit this number, no new Jobs will be issued until
    // exising ones have completed and been processed.
    public int maxTerrainsToSchedule = 4;

    // Dictionary mapping the center of meshes (divided by the dimensions of a
    // given mesh (so the mesh at the origin is (0,0), surrounded by (-1,0),
    // (-1,-1) etc. to TerrainData objects, which represent the properties of
    // each mesh.
    private Dictionary<Vector2Int, TerrainData> meshes = new Dictionary<Vector2Int, TerrainData>();

    // Material array passed to each mesh.  Meshes all use this shared array.
    private Material[] sharedMaterials;

    // Local copies of the objects held in the global GameController.  Used to
    // generate annotations on the Custom Activity Map.
    private Arm.Annotations.CAM armMap;
    private Arm.Annotations.CAM.CAMTrack[] armTracks;

    // The channel used to emit TerrainController activity.
    private Arm.Annotations.Channel terrainControllerChannel;

    // Counter for the number of terrain generations currently going on - used
    // to enforce the maxTerrainsToSchedule limit.
    private int terrainGenerationsInProgress = 0;

    /**
     * Represents a Terrain Tile, and in particular its current state of
     * generation.  There is one of these for every tile in the game.    
     **/
    class TerrainData
    {
        // To support the job scheduler
        public TerrainJob job;
        public JobHandle jobHandle;

        // The GameObject that we are generating into
        public GameObject obj;

        // Flag set when the job completes
        public bool completed;

        // Flag set when the Tile is deleted (Job might still be running in the
        // background)
        public bool deleted;

        // To support the generation of annotations showing various activities.
        private Arm.Annotations.Channel channel;
        Arm.Annotations.CAM.CAMTrack track;

        public TerrainData(Vector3 centerPoint, Arm.Annotations.CAM.CAMTrack track, TerrainController parent)
        {
            completed = false;
            deleted = false;
            this.track = track;
            this.channel = parent.terrainControllerChannel;

            obj = new GameObject();
            obj.name = "Terrain " + centerPoint.ToString();
            obj.AddComponent<MeshFilter>();
            MeshRenderer mr = obj.AddComponent<MeshRenderer>();
            mr.sharedMaterials = parent.sharedMaterials;

            Mesh m = new Mesh();
            m.subMeshCount = 3;

            obj.GetComponent<MeshFilter>().mesh = m;
            job = new TerrainJob(centerPoint, parent);
            jobHandle = job.Schedule();
        }

        /**
         * We periodically call this on every existing TerrainData.
         * It checks to see if the job completed, and if so, does cleanup and
         * makes a new Mesh from all the stuff that the job generated for us.
         * 
         * 
         **/
        public bool completeIfNeeded()
        {
            bool terrainGenerationCompleted = false;

            if (!completed && jobHandle.IsCompleted)
            {
                completed = true;
                jobHandle.Complete();   // Apparently this is required.

                // It is possible that we got deleted before we finished - if so,
                // don't actually do anything with the GameObject.
                if (!deleted)
                {
                    channel.annotate("Completing", Color.blue);

                    Mesh mesh = obj.GetComponent<MeshFilter>().mesh;

                    mesh.vertices = job.vertices.ToArray();
                    mesh.uv = job.uv.ToArray();
                    mesh.uv2 = job.uv2.ToArray();

                    mesh.SetTriangles(job.grassTriangles.ToArray(), 0);
                    mesh.SetTriangles(job.sandTriangles.ToArray(), 1);
                    mesh.SetTriangles(job.waterTriangles.ToArray(), 2);
                    mesh.RecalculateNormals();
                    channel.end();
                    terrainGenerationCompleted = true;
                }

                // Register the start and stop times of the job
                track.registerJob(obj.name, Color.red, job.timings[0], job.timings[1]);

                job.cleanUp();
            }

            return terrainGenerationCompleted;
        }

        public void cleanUp()
        {
            if (!completed)
            {
                // Ensure that the job is complete.
                jobHandle.Complete();

                deleted = true;
                job.cleanUp();
            }

            Destroy(obj.GetComponent<MeshFilter>().mesh);
            Destroy(obj);
        }
    };

    // Use this for initialization
    void Start()
    {
        // Build a shared materials array to use for each of the meshes that we generate.
        sharedMaterials = new Material[3];
        sharedMaterials[0] = grassMaterial;
        sharedMaterials[1] = sandMaterial;
        sharedMaterials[2] = waterMaterial;

        // Build local references to Arm annotation objects.
        GameController gameController = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
        terrainControllerChannel = gameController.terrainControllerChannel;
        armMap = gameController.terrainCAM;
        armTracks = gameController.terrainTracks;

    }

    private void FixedUpdate()
    {
        ensureCorrectTerrainsAround(player.transform.position);
    }

    /**
     * Ensures that the right number of terrains exist around the specified
     * point, and anything not around that point it deleted.
     **/
    void ensureCorrectTerrainsAround(Vector3 center)
    {
        // Generate the terrain key for our current position.
        Vector2Int c = new Vector2Int(Mathf.RoundToInt(center.x / worldDimensions.x), Mathf.RoundToInt(center.z / worldDimensions.z));

        // First cull anything out of range.
        List<Vector2Int> keys = new List<Vector2Int>(meshes.Keys);
        foreach (Vector2Int key in keys)
        {
            if (Mathf.Abs(c.x - key.x) > renderDistance || Mathf.Abs(c.y - key.y) > renderDistance)
            {
                if (!meshes[key].completed)
                {
                    terrainGenerationsInProgress--;
                }
                meshes[key].cleanUp();
                meshes.Remove(key);
            }
            else
            {
                if ( meshes[key].completeIfNeeded() )
                {
                    terrainGenerationsInProgress--;
                }
            }
        }

        // If anything new is created, schedule those new jobs.
        if ( fillGaps(c) )
        {
            JobHandle.ScheduleBatchedJobs();
        }
    }

    /**
     * Looks at the space around the player, and if a required Terrain Tile does
     * not exist, starts generation.
     **/    
    bool fillGaps(Vector2Int c)
    {
        bool someScheduled = false;

        for (int x = c.x - renderDistance; x <= (c.x + renderDistance); x++)
        {
            for (int y = c.y - renderDistance; y <= (c.y + renderDistance); y++)
            {
                Vector2Int testV = new Vector2Int(x, y);
                if (!meshes.ContainsKey(testV))
                {
                    // Don't do anything if we're too busy
                    if (terrainGenerationsInProgress >= maxTerrainsToSchedule)
                    {
                        return true;
                    }

                    // Register that we're doing some work
                    terrainControllerChannel.annotate("Schedule new", Color.green);
                    someScheduled = true;

                    // Creating a new TerrainData object will create a new Job
                    // for the Unity Job Scheduler.
                    Vector3 centerPoint = new Vector3((float)testV.x * worldDimensions.x, 0, (float)testV.y * worldDimensions.z);
                    TerrainData data = new TerrainData(centerPoint, armTracks[terrainGenerationsInProgress], this);
                    terrainGenerationsInProgress++;
                    meshes[testV] = data;

                    // Register that we finished our work.
                    terrainControllerChannel.end();
                }
            }
        }
        return someScheduled;
    }

    private void OnGUI()
    {
        GUI.color = Color.black;

        GUI.Label(new Rect(10, 10, Screen.width - 10, 200),
                  "Tile resolution: " + resolution.x + "x" + resolution.y +
                  "\nTile scale: " + worldDimensions.x + "x" + worldDimensions.z + "x" + worldDimensions.y +
                  "\nGenerations: " + terrainGenerationsInProgress + " of " + maxTerrainsToSchedule);
    }
}

