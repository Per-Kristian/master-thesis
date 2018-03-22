numUsers = numel(fieldnames(monoRefs));
params.blockLength = 500;
params.absThresh = 1.25;

PArunner = PARunner('all', 'all', params, validSets, 'valid', monoRefs, ...
	diRefs, false, 'Without Outliers');

for ii = 1:numUsers
	userName = getUserName(ii);
	monoRef = monoRefs.(userName);
	diRef = diRefs.(userName);
	%{
	triRef = obj.triRefs.(userName);
	fourRef = obj.triRefs.(userName);
	%}
	scores = PArunner.simulate(monoRef, diRef, validSets.(userName));
	persParams.meanScore = nanmean(scores);
	fprintf("Storing %s's threshold: %d\n", userName, persParams.meanScore);
	FileIO.writePersonalPAParams(userName, 'PA', params, persParams);
end