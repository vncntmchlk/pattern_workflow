In this tutorial I want to give you an idea how I use the SC pattern system to compose music.

First I want to show you "chaining" of patterns.  
This is a way to combine multiple patterns into one, which allows use to make complex patterns more simple to handle.

Chaining can be done via "Pchain" or the "<>" operator, the patterns on the right are feeding into the patterns on the left.

```Supercollider
Pchain(pattern_A, pattern_B, pattern_C, ...);

(pattern_A <> pattern_B <> pattern_C <> ...);
```

Chaining is a useful tool when composing, it allows us for example to take the same shape for a melody but exchange the scale in which it is embedded.  
In Pbind use the key \\degree to express a melody in steps in a scale. The default scale is C major. Step 0 is c3.

```SuperCollider
~melody1 = Pbind(
    \degree, Pseq([0,1,2,3,8,2,3]),
    \dur, 1/4,
    \legato, 0.1
);

~melody1.play; // play with default scale

(Pbind(\scale, Scale.chromatic) <> ~melody1).play; // you can use the Scale object of SuperCollider which also allows to change the tuning

~diminished = Pbind(\scale, [0,3,6,9]); // or the simple array notation, for example for a diminshed chord
(~diminished <> ~melody1).play;

// chain multiple patterns (~addNotes is defined in "additionalPatterns.scd"
(~addNotes <> ~diminished <> ~melody1).play;
```

Chaining enables us to add to or manipulate any of the parameters of a pattern, in a modular way.

Next let me show you how we can simply glue patterns into a combined structure using "Pspawner".  
It allows us to play patterns in sequence and in parallel.

```SuperCollider
(
~phrase1 = Pbind(
    \dur, 1/32,
    \degree, Penv([-3,11,-10],[2,2],[10,10,-1]),
    \amp, Penv([0.1,0.001,0.1],[2,2],[5,3,5]),
    \legato, 0.1
);
~phrase2 = Pbind(
    \dur, 2,
    \degree, Pseq([-11,-4,-11]),
    \legato,1
);
)

/*
the elements we define inside Pspawner({ .. }) are processed from top to bottom.
Pspawner parses a "spawner" object which is called "sp" in the following example.
Using the methods "seq", "par" and "wait" we can play patterns in sequence and in parallel.
sp.wait can be used to create a pause before the next pattern is started.
*/

~spawner = Pspawner({|sp|
    ">>> play phrase 1 and 2 sequentially".postln;
    sp.seq(~phrase1);
    sp.seq(~phrase2);
    ">>> wait for 1 beat".postln;
    sp.wait(1);
    ">>> play phrase 1 and 2 in parallel".postln;
    sp.par(~phrase1);
    sp.seq(~phrase2);
});

~spawner.play;

// Pspawner can be used in a Pchain
(~addNotes <> ~spawner).play;
```

A Pspawner can also be sequenced inside a Pspawner, so we use it to create small parts of a piece of music and combine the small parts to put it all together.

Now let's move on to use a "generative" pattern as a source.  
The ~logMap pattern is defined in the file "additionalPatterns.scd".

```SuperCollider
/*
using a note generating pattern now.
This one is called "logistic map".
The output data of the algorithm is mapped to duration and degree of a Pbind.
Depending on its' "grow" value the algorithm will output repetetive or chaotic values.
*/

(~logMap <> Pbind(\grow, 3)).play; // this plays infinitly, use cmd+. to stop
(~logMap <> Pbind(\grow, 3.58)).play;
(~logMap <> Pbind(\grow, 3.99)).play;

(~logMap <> Pbind(\grow,  Penv([3,3.6,3.99],[6,14])).trace).play;


//use a GUI for interactive control

(
var guiObjects = (plotData: [0], growValue: 3);
guiObjects[\player] = (
    // ~midiPattern <>
    //	Pbind(\degree, Pfunc {|ev|	if(ev[\degree] > 0){Rest()}{ev[\degree]}}) <>
    Pbind(\gui, Pfunc{|ev| guiObjects[\plotData] = ev.dataEnv; 0 }) <>
    ~recordPattern <>
    ~chordX <>
    ~accentPattern <>
    ~logMap <>
    Pbind(\grow, Pfunc {guiObjects[\growValue]})
).play(quant: 1);
~makeGUI.(guiObjects);
)
```

With this pattern workflow in mind, let me show you pieces of mine, where I used many of these concepts.