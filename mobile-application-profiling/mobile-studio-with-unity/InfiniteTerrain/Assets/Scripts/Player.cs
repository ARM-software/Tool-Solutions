/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/**
 * Provides something for the camera to chase around the scene.  Not visible.
 **/
public class Player : MonoBehaviour {

    // The maximum speed of movement.  The player's speed fluctuates between
    // this and zero in a sin^2 wave every speedPeriod seconds.
    public float speed = 1.0f;

    // The period of the speed fluctuation
    public float speedPeriod = 10f;

    // The maximum rotation rate, which varies based on the cu
    public float rotationRate = 1.0f;

	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {
        float rotationSpeed = rotationRate * (Mathf.Sin(Time.timeSinceLevelLoad * 1f) * 100f + Mathf.Sin(Time.timeSinceLevelLoad * 0.3f) * 50f);
        Quaternion rot = Quaternion.AngleAxis(rotationSpeed * Time.fixedDeltaTime, Vector3.up);
        Quaternion newRotation = transform.rotation * rot;
        transform.rotation = newRotation;

        float currentSpeed = Mathf.Pow((Mathf.Sin(Mathf.PI * Time.timeSinceLevelLoad / speedPeriod)+1),2f) * speed;

        transform.position += transform.rotation * Vector3.forward * currentSpeed * Time.deltaTime;
    }
}
