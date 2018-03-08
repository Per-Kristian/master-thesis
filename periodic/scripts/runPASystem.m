function runPASystem(user, imposter, probeSets, setType, monoRefs, ...
	diRefs, fast, paramnote, resultnote)

params.type = 'simpleSMD';
params.note = paramnote;
params.blockLength = 50;

PArunner = PARunner(user, imposter, params, probeSets, setType, monoRefs, ...
	diRefs, fast, resultnote);
PArunner.run();
end