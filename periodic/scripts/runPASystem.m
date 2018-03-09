function runPASystem(user, imposter, probeSets, setType, monoRefs, ...
	diRefs, fast, paramnote, resultnote)

params.note = paramnote;
params.blockLength = 250;
params.absThresh = 1.25;

PArunner = PARunner(user, imposter, params, probeSets, setType, monoRefs, ...
	diRefs, fast, resultnote);
PArunner.run();
end