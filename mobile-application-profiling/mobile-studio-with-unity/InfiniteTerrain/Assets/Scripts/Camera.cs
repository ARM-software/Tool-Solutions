/*
 * Copyright (c) 2019 Arm Limited. All rights reserved.
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Camera : MonoBehaviour {

    // The object that we will follow.
    public Transform target;

    // How far ahead of the target to point.
    public float ahead = 0f;

    // Y position of the camera.
    public float camHeight = 5f;

    // Rate at which the camera moves from current position to ideal position
    public float smoothing = 5f;

    // Distance of camera from the target
    public float distance = 5f;

    // Update is called once per frame
	void Update () {

        // Move backwards from where the target is.
        Vector3 targetCamPos = target.rotation * Vector3.back * distance + target.position;

        // Look at a point the right distance in front of the target.
        Vector3 targetLookatPos = target.rotation * Vector3.forward * ahead + target.position;

        // Fix our Y position.
        targetCamPos.y = camHeight;

        // Move from where we are now towards where we want to be.
        transform.position = Vector3.Lerp(transform.position, targetCamPos, smoothing * Time.deltaTime);

        // Point the camera
        transform.LookAt(targetLookatPos);
    }
}
