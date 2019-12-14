# ChucK-sta-pose
The audio component of my final project for Music and Tech 1.

## Concept
Control a musical piece with gesture control. 

I will leverage existing tech solutions to design a multifaceted, neural-network-driven system which allows the user to conduct a musical piece with nothing more than a laptop and a webcam.

## Execution
There are three discrete components required to achieve the goal.

1. Audio backend
    * ChucK audio engine
    * OSC input
    * Use gesture classification and params to control piece
2. Pose tracking software
    * https://github.com/tommymitch/posenetosc
    * Sends pose data over OSC
3. Gesture classifier
    * Use Wekinator "dynamic time warp" model, perfect for sequence classification.
    * Train several poses
    * Stream pose data for on-the-fly gesture classification.
    * Utilize second model to parameterize poses (i.e. arm is raised 75%)
    * Native OSC input/output
   
## Install
1. Pull this repo.
2. Pull the repo https://github.com/tommymitch/posenetosc
   * Move the `osc.send(message)` on line 300 to line 301 so it is after the `}`. This ensures the message is sent correctly.
   
## Run
1. Run `chuck.sh`
2. Run `node bridge.js` in the `posenetosc` repo
3. Run `yarn watch` in the `posenetosc` repo. This will open up a window in your browser.
4. Load, train, and run the wekinator model in `/pose_parameters`.
   
## Audio Backend
A composed chuck piece consisting of several audio sources.

There are two scripts in the audio engine:

`main.ck`: 
* Audio sources
* OSC event listeners (note trigger, instrument params)
    
`composition.ck`: 
* High-level control of audio sources
* Several distinct sections
* OSC event listeners (gesture data, gesture parameters)
   
## Gesture Classification (Failure)
Wekinator allows me to classify multiple, complex gestures.

Some gestures are:

`raise_arm`: Raise the volume of a single voice
* Use `hand_y` parameter to control volume
* Use some other parameter to determine which voice is selected

`lower_arm`: Lower the volume of a single voice
* Same as `raise_arm`

`arms_wide`: Controll all voices simultaneously

`inward_circle`: Used to note a sudden "closing" or cut-off.

Note: I may use two classifiers (one for left, one for right)


## Pose Parameterization
Using Wekinators continuous model, I can supplant the gesture classifications with data about the pose.

Here are some of proposed parameters:

`hand_x`, `hand_y`: 0.0 - 1.0

`arm_angle`: 0.0 - 1.0

`elbow_angle`: 0.0 - 1.0
