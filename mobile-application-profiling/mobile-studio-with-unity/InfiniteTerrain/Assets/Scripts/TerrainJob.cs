/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Collections;
using Unity.Jobs;
using System;

struct TerrainJob : IJob
{
    [ReadOnly] public Vector3 center;
    [ReadOnly] private Vector3 worldDimensions; // Dimensions of a given mesh, we tile the world with these.
    [ReadOnly] private Vector2Int resolution;   // The number of X and Z points within that mesh.
    [ReadOnly] private float landscapeSeed;     // Seed applied to the perlin noise generation function.
    [ReadOnly] private float landscapeScale;
    [ReadOnly] private float terrainSeed;       // Seed applied to the perlin noise generation function.
    [ReadOnly] private float terrainScale;
    [ReadOnly] private float waterLevel;
    [ReadOnly] private float waterSpace;

    public NativeArray<Vector3> vertices;
    public NativeArray<Vector2> uv;
    public NativeArray<Vector2> uv2;
    public NativeArray<int> grassTriangles;
    public NativeArray<int> sandTriangles;
    public NativeArray<int> waterTriangles;
    public NativeArray<UInt64> timings;

    public TerrainJob(Vector3 _center, TerrainController parent)
    {
        center = _center;
        worldDimensions = parent.worldDimensions;
        resolution = parent.resolution;
        landscapeSeed = parent.landscapeSeed;
        landscapeScale = parent.landscapeScale;
        terrainSeed = parent.terrainSeed;
        terrainScale = parent.terrainScale;
        waterLevel = parent.waterLevel;
        waterSpace = parent.waterSpace;

        // 6 vertexes for land quad, 6 for water quad.
        vertices = new NativeArray<Vector3>(resolution.x * resolution.y * 12, Allocator.Persistent);
        uv = new NativeArray<Vector2>(vertices.Length, Allocator.Persistent);
        uv2 = new NativeArray<Vector2>(vertices.Length, Allocator.Persistent);
        grassTriangles = new NativeArray<int>(resolution.x * resolution.y * 6, Allocator.Persistent);
        sandTriangles = new NativeArray<int>(resolution.x * resolution.y * 6, Allocator.Persistent);
        waterTriangles = new NativeArray<int>(resolution.x * resolution.y * 6, Allocator.Persistent);

        timings = new NativeArray<UInt64>(2, Allocator.Persistent);
    }

    public void cleanUp()
    {
        vertices.Dispose();
        uv.Dispose();
        uv2.Dispose();
        grassTriangles.Dispose();
        sandTriangles.Dispose();
        waterTriangles.Dispose();
        timings.Dispose();
    }

    private static float worldFromPoint(float point, float center, float length, int res)
    {
        return center - length / 2f + (point * length / res);
    }

    private Vector2 worldXZFromPoint(Vector3 center, float x, float z)
    {
        float xoffset = -Mathf.Abs((z % 2f) - 1f) * 0.5f * (worldDimensions.x / resolution.x);
        float wx = worldFromPoint(x, center.x, worldDimensions.x, resolution.x) + xoffset;
        float wz = worldFromPoint(z, center.z, worldDimensions.z, resolution.y);
        return new Vector2(wx, wz);
    }

    // Coordinates are in the range 0..resolution.x or z, so we end up with
    // resolution.x or z patches wide and deep.
    private Vector3 worldFromPoint(Vector3 center, int x, int z, bool perlinHeight)
    {
        Vector2 worldXZ = worldXZFromPoint(center, x, z);
        float wy = waterLevel + waterSpace;

        if (perlinHeight)
        {
            // for (int i = 0; i < 200; i++)
            {
                float perlin = Mathf.PerlinNoise(worldXZ.x * landscapeScale + landscapeSeed, worldXZ.y * landscapeScale);
                float perlin2 = Mathf.PerlinNoise(worldXZ.x * landscapeScale * 3f + landscapeSeed, worldXZ.y * landscapeScale * 3f);
                float height = Mathf.Clamp((Mathf.Abs(perlin * perlin2 - 0.5f) * 2f - waterLevel) / (1f - waterLevel), 0f, 1f);

                wy += height * worldDimensions.y;
            }
            //wy /= 200f;

        }
        return new Vector3(worldXZ.x, wy, worldXZ.y);
    }

    private bool isSand(Vector3 center, float x, float z)
    {
        Vector2 worldXZ = worldXZFromPoint(center, x, z);
        return Mathf.PerlinNoise(worldXZ.x * terrainScale + terrainSeed, worldXZ.y * terrainScale) > 0.5f;
    }

    private int pointToVertex(int x, int y)
    {
        return x + resolution.x * y;
    }

    private Vector2 uvFromPoint(float x, float z)
    {
        float xoffset = -Mathf.Abs((z % 2f) - 1f) * 0.5f;

        return new Vector2((x + xoffset) / resolution.x, z / resolution.y);
    }

    public void Execute()
    {
        timings[0] = Arm.Annotations.getTime();

        // Set up all the vertices.
        int index = 0;
        int grassIndex = 0;
        int sandIndex = 0;
        int waterIndex = 0;

        System.Random random = new System.Random();

        for (int z = 0; z < resolution.y; z++)
        {
            for (int x = 0; x < resolution.x; x++)
            {
                /*  x,z+1    x+1,z+1
                 *      +-------+
                 *      |1   2,4| 
                 *      |       |
                 *      |0,3   5|
                 *      +-------+
                 *  x,z     x+1,z
                 */

                // Land quad
                vertices[index] = worldFromPoint(center, x, z, true);
                vertices[index + 1] = worldFromPoint(center, x, z + 1, true);
                vertices[index + 2] = worldFromPoint(center, x + 1, z + 1, true);
                vertices[index + 3] = worldFromPoint(center, x, z, true);
                vertices[index + 4] = worldFromPoint(center, x + 1, z + 1, true);
                vertices[index + 5] = worldFromPoint(center, x + 1, z, true);

                // Water quad
                vertices[index + 6] = worldFromPoint(center, x, z, false);
                vertices[index + 7] = worldFromPoint(center, x, z + 1, false);
                vertices[index + 8] = worldFromPoint(center, x + 1, z + 1, false);
                vertices[index + 9] = worldFromPoint(center, x, z, false);
                vertices[index + 10] = worldFromPoint(center, x + 1, z + 1, false);
                vertices[index + 11] = worldFromPoint(center, x + 1, z, false);

                // Generate random UV X coordinates into the texture.
                float texV = ((z == 0) || (x == 0)) ? 0.25f : 0.75f;

                bool tri1isSand = isSand(center, (float)x + 0.3f, (float)z + 0.7f);
                uv[index] = new Vector2((float)random.NextDouble(), texV);
                uv[index + 1] = new Vector2((float)random.NextDouble(), texV);
                uv[index + 2] = new Vector2((float)random.NextDouble(), texV);

                bool tri2isSand = isSand(center, (float)x + 0.7f, (float)z + 0.3f);
                uv[index + 3] = new Vector2((float)random.NextDouble(), texV);
                uv[index + 4] = new Vector2((float)random.NextDouble(), texV);
                uv[index + 5] = new Vector2((float)random.NextDouble(), texV);

                // Generate UVs for the water vertices.
                for (int c = 6; c < 12; c++)
                {
                    uv[index + c] = new Vector2((float)random.NextDouble(), texV);
                }

                // UV2 is smooth 0-1 across the mesh, generate for land quad
                uv2[index] = uvFromPoint(x, z);
                uv2[index + 1] = uvFromPoint(x, z + 1);
                uv2[index + 2] = uvFromPoint(x + 1, z + 1);
                uv2[index + 3] = uvFromPoint(x, z);
                uv2[index + 4] = uvFromPoint(x + 1, z + 1);
                uv2[index + 5] = uvFromPoint(x + 1, z);

                // Copy texture UV2 from land vertices to water vertices
                for (int c = 0; c < 6; c++)
                {
                    uv2[index + c + 6] = uv2[index + c];
                }

                // Triangle 1
                if (tri1isSand)
                {
                    sandTriangles[sandIndex] = index;
                    sandTriangles[sandIndex + 1] = index + 1;
                    sandTriangles[sandIndex + 2] = index + 2;
                    sandIndex += 3;
                }
                else
                {
                    grassTriangles[grassIndex] = index;
                    grassTriangles[grassIndex + 1] = index + 1;
                    grassTriangles[grassIndex + 2] = index + 2;
                    grassIndex += 3;
                }

                if (tri2isSand)
                {
                    sandTriangles[sandIndex] = index + 3;
                    sandTriangles[sandIndex + 1] = index + 4;
                    sandTriangles[sandIndex + 2] = index + 5;
                    sandIndex += 3;
                }
                else
                {
                    grassTriangles[grassIndex] = index + 3;
                    grassTriangles[grassIndex + 1] = index + 4;
                    grassTriangles[grassIndex + 2] = index + 5;
                    grassIndex += 3;
                }

                // Generate the water triangles.
                waterTriangles[waterIndex] = index + 6;
                waterTriangles[waterIndex + 1] = index + 7;
                waterTriangles[waterIndex + 2] = index + 8;
                waterTriangles[waterIndex + 3] = index + 9;
                waterTriangles[waterIndex + 4] = index + 10;
                waterTriangles[waterIndex + 5] = index + 11;
                waterIndex += 6;

                index += 12;
            }
        }

        timings[1] = Arm.Annotations.getTime();
    }
};