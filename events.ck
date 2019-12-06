// Custom events for neatly storing parameters ========================================
public class OSCEvent extends Event {
    string oscArgs; // osc args are included here to make editing of subclasses easy

    fun void fromMsg(OscMsg msg) {  // Parse message to message parameters
        <<<"Not implemented">>>;
    }
}

public class ParamEvent extends OSCEvent {
    fun void setParams(UGen ugen) {
        <<<"Not implemented">>>;
    }
}

public class NoteEvent extends OSCEvent {
    "i i" => oscArgs;

    0 => int noteVal;
    0 => int isOn;

    fun void fromMsg(OscMsg msg) {
        msg.getInt(0) => isOn;
        msg.getInt(1) => noteVal;
    }
}

public class FiltEvent extends ParamEvent {
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

public class DelayEvent extends ParamEvent {
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

public class PanEvent extends ParamEvent {
    "f" => oscArgs;

    0 => float pan;

    fun void fromMsg(OscMsg msg) {
        msg.getFloat(0) => pan;
    }

    fun void setParams(UGen ugen) {
        pan => (ugen $ Pan8).pan;
    }
}
