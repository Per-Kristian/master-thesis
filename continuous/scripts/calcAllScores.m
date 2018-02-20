function calcAllScores(setType, monoRefs, diRefs, probeSets)
numUsers = numel(fieldnames(probeSets));
for ii = 1:numUsers
	userName = getUserName(ii);
	fprintf('Calculating scores for %s\n', userName);
	monoRef = monoRefs.(userName);
	diRef = diRefs.(userName);
	matcher = Matcher(monoRef, diRef);
	for jj = 1:numUsers
		imposterName = getUserName(jj);
		probeSet = probeSets.(imposterName);
		scores = matcher.preCalcSimpleSMDScores(probeSet);
		FileIO.writeScores(userName, imposterName,'simpleSMD',setType,scores);
	end
end
end