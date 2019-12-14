6666 => int inPort;
6667 => int outPort;

["nose", "leftEye", "rightEye", "leftEar", "rightEar", 
"leftShoulder", "rightShoulder", "leftElbow", "rightElbow", 
"leftWrist", "rightWrist", "leftHip", "rightHip", 
"leftKnee", "rightKnee", "leftAnkle", "rightAnkle"] @=> string partNames[];

class Point {
    float x;
    float y;

    fun void set(float x, float y) {
        x => this.x;
        y => this.y;
    }
}

class Pose {
    Point @ points[0];
    string parts[0];

    fun void addPart(string name, float x, float y) {
        Point p;
        p.set(x, y);
        p @=> points[name]; 
        parts << name;
    }

    fun void fromMsg(OscMsg msg) {
        for (int i; i < 17; i++) {
            i * 3 => int offset;
            msg.getString(offset) => string name;
            msg.getFloat(offset+1) => float px;
            msg.getFloat(offset+2) => float py;
            if (name != "") {
                addPart(name, px, py);
            }
        }
    }

    fun void print() {
        for (int i; i < parts.size(); i++) {
            <<<parts[i], points[parts[i]].x, points[parts[i]].y>>>;
        }
        <<<"","\n">>>;
    }
}

fun Point v_sub(Point a, Point b) {
    Point ab;
    ab.set(a.x - b.x, a.y - b.y);
    return ab;
}

fun float mag(Point a) {
    return Math.sqrt(a.x*a.x + a.y*a.y);
}

fun float dot(Point a, Point b) {
    return a.x * b.x + a.y * b.y;
}

fun float angleAtoC(Point a, Point b, Point c) {
    v_sub(a, b) @=> Point @ ab;
    v_sub(c, b) @=> Point @ bc;
    // return Math.acos(dot(ab, bc) / (mag(ab) * mag(bc)));
    return Math.atan2(ab.y, ab.x) - Math.atan2(bc.y, bc.x);
}

fun float deg2rad(float radian) {
    return 180 * radian / Math.PI;
}

class Feature {
    float leftShoulderAngle;
    float rightShoulderAngle;
    float leftElbowAngle;
    float rightElbowAngle;
    Point leftHand;
    Point rightHand;

    fun void fromPose(Pose p) {
        int hasPart[0];
        for (int i; i < partNames.size(); i++) {
            0 => hasPart[partNames[i]];
        }
        for (int i; i < p.parts.size(); i++) {
            1 => hasPart[p.parts[i]];
        }

        // right shoulder angle
        if (hasPart["leftShoulder"] && hasPart["rightShoulder"] && hasPart["rightElbow"]) {
            angleAtoC(p.points["leftShoulder"], p.points["rightShoulder"], p.points["rightElbow"]) => rightShoulderAngle;
            (deg2rad(rightShoulderAngle) + 270 ) % 360 => rightShoulderAngle;
        }

        // left shoulder angle
        if (hasPart["rightShoulder"] && hasPart["leftShoulder"] && hasPart["leftElbow"]) {
            angleAtoC(p.points["rightShoulder"], p.points["leftShoulder"], p.points["leftElbow"]) => leftShoulderAngle;
            (deg2rad(leftShoulderAngle)  + 270 ) % 360 => leftShoulderAngle;
        }

        // right elbow angle
        if (hasPart["rightShoulder"] && hasPart["rightElbow"] && hasPart["rightWrist"]) {
            angleAtoC(p.points["rightShoulder"], p.points["rightElbow"], p.points["rightWrist"]) => rightElbowAngle;
        }

        // left elbow angle
        if (hasPart["leftShoulder"] && hasPart["leftElbow"] && hasPart["leftWrist"]) {
            angleAtoC(p.points["leftShoulder"], p.points["leftElbow"], p.points["leftWrist"]) => leftElbowAngle;
        }
    }

    fun void sendOSC(OscOut xmit) {
        xmit.start("/feature/0");
        leftShoulderAngle => xmit.add;
        rightShoulderAngle => xmit.add;
        leftElbowAngle => xmit.add;
        rightElbowAngle => xmit.add;
        leftHand.x => xmit.add;
        leftHand.y => xmit.add;
        rightHand.x => xmit.add;
        rightHand.y => xmit.add;
        xmit.send();
    }

    fun void print() {
        <<<"Left Shoulder θ:", leftShoulderAngle>>>;
        <<<"Right Shoulder θ:", rightShoulderAngle>>>;
        <<<"Left Elbow θ:", deg2rad(leftElbowAngle)>>>;
        <<<"Right Elbow θ:", deg2rad(rightElbowAngle)>>>;
        // <<<"Left Hand Centered Pos", leftHand_x, leftHand_y>>>;
        // <<<"Right Hand Centered Pos", rightHand_x, rightHand_y>>>;
    }
}


// Input from pose tracker
OscIn oin;
OscMsg msg;
inPort => oin.port;
oin.addAddress("/pose/0");

// Forward feature to pose classifier
OscOut xmit;
xmit.dest( "localhost", outPort );

while(true) {
    oin => now;
    while (oin.recv(msg) != 0) {
        // Parse pose data
        Pose p;
        p.fromMsg(msg);
        // p.print();

        // Extract features
        Feature f;
        f.fromPose(p);
        // f.print();

        // Forward feature to pose classifier
        f.sendOSC(xmit);
    }
}