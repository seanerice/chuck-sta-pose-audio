// Custom events for neatly storing parameters ========================================
class OSCEvent extends Event {
    string oscArgs; // osc args are included here to make editing of subclasses easy

    fun void fromMsg(OscMsg msg) {  // Parse message to message parameters
        <<<"Not implemented">>>;
    }
}

class ParamEvent extends OSCEvent {
    fun void setParams(UGen ugen) {
        <<<"Not implemented">>>;
    }
}

class NoteEvent extends OSCEvent {
    "i i" => oscArgs;

    0 => int noteVal;
    0 => int isOn;

    fun void fromMsg(OscMsg msg) {
        msg.getInt(0) => isOn;
        msg.getInt(1) => noteVal;
    }
}

class FiltEvent extends ParamEvent {
    "f f" => oscArgs;

    1000 => float cutoff;
    1 => float peak;

    fun void fromMsg(OscMsg msg) {
        msg.getFloat(0) => cutoff;
        msg.getFloat(1) => peak;
    }

    fun void setParams(UGen ugen) {
        (ugen $ LPF).set(cutoff, peak);
    }
}

class DelayEvent extends ParamEvent {
    "f f" => oscArgs;

    0 => float feedback;
    0 => float t;

    fun void fromMsg(OscMsg msg) {
        msg.getFloat(0) => feedback;
        msg.getFloat(1) => t;
    }

    fun void setParams(UGen ugen) {
        feedback => (ugen $ Echo).mix;
        t::second => (ugen $ Echo).delay;
    }
}

class PanEvent extends ParamEvent {
    "f" => oscArgs;

    0 => float pan;

    fun void fromMsg(OscMsg msg) {
        msg.getFloat(0) => pan;
    }

    fun void setParams(UGen ugen) {
        pan => (ugen $ Pan8).pan;
    }
}
// Audio Sources ======================================================================
// Base class for a pannable, OSC-controlled audio source
class OSCHandler {
    // Start OSC event listeners
    OscIn oin;
    OscMsg msg;
    6449 => oin.port;
    "audiosource" => string addrPrefix;

    // Map of OSC addresses (string) to events (OSCEvent)
    OSCEvent @ eventBindings[0];
    string usedAddrs[0];
    string addrArgs[0];

    spork ~ oscEventHandle();

    fun void bindOscEvent(string addr, OSCEvent e) {
        e @=> eventBindings[addr];
        usedAddrs << addr;
        addrArgs << e.oscArgs;
    }

    // Handle incoming OSC messages;
    // "Route" messages to correct event handler using eventBindings table
    // and signal an event
    fun void oscEventHandle() {
        while(true) {
            oin => now;
            while (oin.recv(msg) != 0) {
                eventBindings[msg.address].fromMsg(msg);
                eventBindings[msg.address].signal();
            }
        }
    }

    // Start OSC listening on bound addresses
    fun void initOSC() {
        for (int i; i < usedAddrs.size(); i++) {
            usedAddrs[i] => string addr;
            addrArgs[i] => string args;

            // OscIn will listen on this address and route messages to the bound event
            oin.addAddress(addr + ", " + args);
            <<<"Create binding: " + addr + ", " + args>>>;
        }
    }
}

class FileSource {
    SndBuf buf => Envelope env => LPF lpf => Echo delay => Pan8 pan => dac;
    
    // Initial parameters
    10000 => lpf.freq;
    1 => lpf.Q;
    
    0 => delay.mix;

    "filesource" => string prefix;

    // Event objects
    NoteEvent playNote;
    DelayEvent changeDelay;
    FiltEvent changeFilter;
    PanEvent changePan;

    // Even listener shreds
    spork ~ noteEventListener(playNote);
    spork ~ paramEventListener(changeDelay, delay);
    spork ~ paramEventListener(changeFilter, lpf);
    spork ~ paramEventListener(changePan, pan);

    OSCHandler osch;

    fun void noteEventListener(NoteEvent ne) {
        while(true) {
            ne => now;
            if (ne.isOn) {
                play();
            } else {
                stop();
            }
        }
    }

    fun void paramEventListener(ParamEvent oe, UGen ugen) {
        while(true) {
            oe => now;
            oe.setParams(ugen);
        }
    }

    fun void read(string filename) {
        me.dir() + filename => buf.read;
        0 => buf.rate;
    }

    fun void play() {
        0 => env.value;
        env.keyOn();
        0 => buf.pos;
        1 => buf.rate;
        <<<prefix + ": Playing note.">>>;
    }

    fun void stop() {
        0 => buf.rate;
    }

    fun void initOsc(string prefix) {
        prefix => this.prefix;
        osch.bindOscEvent(prefix + "/playnote", playNote);
        osch.bindOscEvent(prefix + "/delay", changeDelay);
        osch.bindOscEvent(prefix + "/lpf", changeFilter);
        osch.bindOscEvent(prefix + "/pan8", changePan);
        osch.initOSC();
    }
}


FileSource fs1;
"Textures/Tambo Gritty Texture.wav" => fs1.read;
fs1.initOsc("/fs1");

FileSource fs2;
"Textures/Wooden Shells.wav" => fs2.read;
fs2.initOsc("/fs2");

FileSource fs3;
"Cassette Noise/Cassette Noise 1.wav" => fs3.read;
fs3.initOsc("/cassette");

while(true) {
    10::ms => now;
}
