~speedUp = Pbind(\dur, Pfunc{ |ev| ev[\dur] * 2/3});
~slowDown = Pbind(\dur, Pfunc{ |ev| ev[\dur] * 3/2});
~chordX = Pbind(\scale, [0, 3, 4, 8, 11, 13]);
~wholeTone = Pbind(\scale, [0, 2, 4, 6, 8, 10]);
~noChange = Pbind();

~addNotes = Pbind(
	\degree, Pfunc {|ev| [
		ev[\degree],
		ev[\degree] + [-2,2].choose,
		ev[\degree] + [4,5].choose
	]},
	\amp, [0.3, 0.1, 0.05],
	\legato, [0.1, 0.3, 1.5]
);

~accentPattern = Pbind(
	\amp, Pfunc{
		var ampMap = Env([0.5, 0.1, 0.35, 0.1, 0.45, 0.1, 0.35, 0.1],[1/2], [-1,10]);
		ampMap[thisThread.clock.beatInBar]
	}
);

/*
~mOut = ConnectVirmidi();
~midiPattern = Pbind(\type, \midi, \midiout, ~mOut);
*/

~logMap = Pbind(
	\grow, Pfunc {|ev|
		if(ev[\grow].notNil){ev[\grow]}{3.61}
	},
	\algo, Prout { |inval|
		var valNow = 0.5;
		var lmap = { |val, grow| grow * val * (1 - val) };
		loop {
			var nextVal = lmap.(valNow, inval[\grow]);
			var diff = nextVal - valNow;
			var dur = (diff.abs / 2).lincurve(0,0.4,1/16,1/4,2).round(1/16);
			var deg = (diff * 10).round(1);
			valNow = nextVal;
			inval[\dur] = dur;
			inval[\degree] = deg;
			inval = yield(inval);
		}
	}
);

~recordPattern = Pbind(
	\record, Prout { |inval|
		var data = List.new();
		loop {
			var timeNow = thisThread.clock.beats;
			var removeIndex = -1;
			var env;
			data.do {|arr, index| if((timeNow - arr[0]) > 4){removeIndex = index}};
			if(removeIndex >= 0){(data.size - removeIndex).do {data.pop}};
			data.addFirst([timeNow, inval.degree]);
			if(data.size > 2){
				env = Env(data.flop[1], (timeNow - data.flop[0]).differentiate, \step).discretize(200);
			}{env = [0]};
			inval[\dataEnv] = env;
			inval = yield(inval);
		}
	}
);

~makeGUI = {|objects|
	var win = Window.new().front;
	var showValue;
	var growSlider;
	var plotter;
	var updateRoutine;
	win.view.decorator = FlowLayout( win.view.bounds, 10@10, 20@5 );
	growSlider =Slider(win.view,200@30).action_({
		objects[\growValue] = growSlider.value.linlin(0,1,3,4);
		showValue.string_(objects[\growValue].asStringPrec(5))
	});
	showValue = StaticText(win.view, 60@30);

	plotter = Plotter(bounds: Rect(0,0,380,350), parent:win.view);
	plotter.plotMode_('levels');

	updateRoutine = Routine {
		loop {
			plotter.setValue(objects[\plotData], minval:-10,maxval:10);
			(1/24).wait
		}
	}.play(AppClock);
	win.onClose_({objects[\player].stop; updateRoutine.stop}); // Stop playing when window is closed
};
