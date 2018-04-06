function runCombSA(user, imposter, probeSets, setType, monoRefs, ...
	diRefs, fast, paramNote, resultNote)
%RUNCOMB Summary of this function goes here
%   Detailed explanation goes here
params.CA.rwrdThreshold = 1.3;
params.CA.tolerance = NaN;
params.CA.width = 0.28;
params.CA.maxRwrd = 1;
params.CA.maxPen = 1;
params.CA.singleOccScore = 2.45;
params.CA.missingScore = 2.75;
params.CA.lockout = 50;
params.CA.type = 'simpleSMD';
params.CA.note = paramNote;

params.PA.blockLength = 500;
params.PA.absThresh = 1.25;
params.PA.tolerance = 0.33;
params.PA.note = paramNote;

params.infl.type = 'decisionLevel';
params.infl.upMult = 0.3;
params.infl.downMult = 0.3;

runner = CombRunner(user, imposter, params, probeSets, setType, ...
	monoRefs, diRefs, fast, resultNote, 'comb_SA');
runner.run();
end

