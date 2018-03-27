function runPASystem(user, imposter, probeSets, setType, monoRefs, ...
	diRefs, fast, paramnote, resultnote)

params.blockLength = 250;
params.absThresh = 1.25;
params.tolerance = 0.001;
params.note = paramnote;

PArunner = PARunner(user, imposter, params, probeSets, setType, monoRefs, ...
	diRefs, fast, resultnote);
PArunner.run();
end