function calcAllPAScores(monoRefs, diRefs, probeSets)
%CALCALLPASCORES Summary of this function goes here
%   Detailed explanation goes here
numUsers = numel(fieldnames(probeSets));
params.blockLength = 500;
params.absThresh = 1.25;

runner = PARunner('all', 'all', params, probeSets, 'test', monoRefs, ...
	diRefs, false, '');
for ii = 19:numUsers
	userName = getUserName(ii);
	fprintf('Calculating scores for %s\n', userName);
	tic
	monoRef = monoRefs.(userName);
	diRef = diRefs.(userName);
	
	for jj = 1:numUsers
		imposterName = getUserName(jj);
		probeSet = probeSets.(imposterName);
		scores = runner.simulate(monoRef, diRef, probeSet);
		FileIO.writePAScores(userName, imposterName,'PA','test',scores,params);
	end
	toc
end
end

