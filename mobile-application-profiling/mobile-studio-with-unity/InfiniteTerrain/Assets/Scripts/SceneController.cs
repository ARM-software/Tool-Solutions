/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Arm;
using UnityEngine.SceneManagement;

public class SceneController : MonoBehaviour {

    // The string to use for the Arm annotation when this scene begins.
    public string sceneDescription;

    // The color of the Arm annotation when this scene begins.
    public Color sceneColor;

    void Start()
    {
        GameController gc = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
        gc.registerScene(sceneDescription, sceneColor);
    }

}
