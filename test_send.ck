"localhost" => string hostname;
6449 => int port;

// get command line
if( me.args() ) me.arg(0) => hostname;
if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// send object
OscOut xmit;
xmit.dest( hostname, port );

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

fun void filterLFO(string addr) {
    OscOut xmit;
    xmit.dest( hostname, port );
    
    0 => float t;
    
    while(true) {
        Std.fabs(Math.sin(t)) * 2000 + 100 => float cutoff;
        setFilter(xmit, addr, cutoff, 5);
        t + 0.001 => t;
        1::ms => now;
    }
}

spork ~ filterLFO("/cassette/lpf");

while( true )
{   
    noteOn(xmit, "/cassette/playnote", 69);
    1::second => now;
}
