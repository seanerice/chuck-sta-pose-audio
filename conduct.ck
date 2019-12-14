"localhost" => string hostname;
6668 => int inPort;
6669 => int outPort;

// get command line
if( me.args() ) me.arg(0) => hostname;
if( me.args() > 1 ) me.arg(1) => Std.atoi => inPort;

// send object
OscOut xmit;
xmit.dest( hostname, outPort );

fun float lerp(float t, float from, float to) {
    return from + t * (to - from);
}

fun void noteOn(OscOut xmit, string addr, int midi) {
    xmit.start(addr);
    1 => xmit.add;
    midi => xmit.add;
    xmit.send();
}

fun void noteOff(OscOut xmit, string addr) {
    xmit.start(addr);
    0 => xmit.add;
    0 => xmit.add;
    xmit.send();
}

fun void setDelay(OscOut xmit, string addr, float feedback, float seconds) {
    xmit.start(addr);
    feedback => xmit.add;
    seconds => xmit.add;
    xmit.send();
}

fun void setFilter(OscOut xmit, string addr, float cutoff, float peak) {
    xmit.start(addr);
    cutoff => xmit.add;
    peak => xmit.add;
    xmit.send();
}

fun void setVolume(OscOut xmit, string addr, float vol) {
    xmit.start(addr);
    vol => xmit.add;
    xmit.send();
}

fun void filterLFO(string addr) {
    OscOut xmit;
    xmit.dest( hostname, outPort );
    
    0 => float t;
    
    while(true) {
        Std.fabs(Math.sin(t)) * 2000 + 100 => float cutoff;
        setFilter(xmit, addr, cutoff, 5);
        t + 0.001 => t;
        1::ms => now;
    }
}

spork ~ filterLFO("/cassette/lpf");

class Conductor {
    FloatSmooth leftArmRaise;
    FloatSmooth rightArmRaise;
    FloatSmooth bothArmRaise;

    Timpani timpani;
    Choir choir;

    spork ~ listenForParams();
    fun void listenForParams() {
        // Input from pose tracker
        OscIn oin;
        OscMsg msg;
        inPort => oin.port;
        oin.addAddress("/pose/parameters");
        while(true) {
            oin => now;
            while(oin.recv(msg) != 0) {
                leftArmRaise.next(msg.getFloat(0));
                rightArmRaise.next(msg.getFloat(1));
                bothArmRaise.next(msg.getFloat(2));
                
                if (rightArmRaise.avg() > 0.75) {
                    <<<"Timpani">>>;
                    timpani.swell(leftArmRaise.avg());
                } else if (rightArmRaise.avg() > 0.25) {
                    <<<"Choir">>>;
                    choir.swell(leftArmRaise.avg());
                } else if (rightArmRaise.avg() > 0.25) {

                } else {
                    // do nothing
                }
            }
        }
    }

    fun void print() {
        <<<"Left Arm Raise:", leftArmRaise.avg()>>>;
        <<<"Right Arm Raise:", rightArmRaise.avg()>>>;
    }
}

class FloatSmooth {
    float queue[0];
    int size;

    fun float avg() {
        if (size <= 0) return 0.0;
        float sum;
        for (int i; i < size; i++) {
            sum + queue[i] => sum;
        }
        return sum / size;
    }

    fun void next(float f) {
        if (size < 15) {
            queue << f;
            size + 1 => size;
        } else {
            shift();
            f => queue[14];
        }
    }

    fun void shift() {
        for (int i; i < size - 1; i++) {
            queue[i+1] => queue[i];
        }
    }
}

class Timpani {
    0 => float vol;
    1::second => dur speed;
    "/timpani" => string address;
    // [0.25, 0.5, 0.75, 1.0] => dur times;

    fun void swell(float t) {
        lerp(t, 0.0, 1.0) => vol;
        1::second * lerp(t, 1.0, 0.1) => speed;
        <<<speed, vol>>>;
    }

    spork ~ update();
    fun void update() {
        OscOut xmit;
        xmit.dest(hostname, outPort);
        0.5::second => dur T;
        T - (now % T) => now;
        while(true) {
            setVolume(xmit, address + "/vol", vol);
            100::ms => now;
        }
    }

    spork ~ play();
    fun void play() {
        OscOut xmit;
        xmit.dest(hostname, outPort);
        while(true) {
            noteOn(xmit, address + "/playnote", 69);
            speed => now;
        }
    }
}

class Choir {
    0.1 => float vol;
    0 => float t;

    fun void swell(float t) {
        lerp(t, 0.0, 1.0) % 0.25 => vol;
        t => this.t;
        // 1::second * lerp(t, 1.0, 0.1) => speed;
        // <<<speed, vol>>>;
    }

    spork ~ update();
    fun void update() {
        OscOut xmit;
        xmit.dest(hostname, outPort);
        while(true) {
            setVolume(xmit, "/choir1/vol", vol);
            setVolume(xmit, "/choir2/vol", vol);
            100::ms => now;
        }
    }

    spork ~ play();
    fun void play() {
        OscOut xmit;
        xmit.dest(hostname, outPort);
        while(true) {
            noteOn(xmit, "/choir1/playnote", 69);
            noteOn(xmit, "/choir2/playnote", 69);
            4::second => now;
        }
    }
}

Conductor conductor;

while( true )
{   
    // noteOn(xmit, "/timpani/playnote", 69);
    1::second => now;
}
