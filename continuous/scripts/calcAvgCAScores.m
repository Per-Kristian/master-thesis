params.rwrdThreshold = 1.85;
params.width = 0.28;
params.maxRwrd = 1;
params.maxPen = 1;
params.singleOccScore = 3;
params.missingScore = 3.3;
params.type = 'simpleSMD';
setType = 'validation';
minimumThreshold = 50;

numUsers = numel(fieldnames(monoRefs));

for ii = 1:numUsers
	userName = getUserName(ii);
	scores = FileIO.readScores(userName, userName, 'CA_simpleSMD', setType);
	scoresWithoutOutliers = FeatureExtractor.removeOutliers(scores);
	tmpPersParams = FileIO.readPersonalParams(userName, 'CA_simpleSMD');
	if ~isempty(tmpPersParams)
		persParams = tmpPersParams;
	else
		persParams = struct();
	end
	
	persParams.meanScore = nanmean(scoresWithoutOutliers);
	
	fprintf("Storing %s's personal params: %d\n", userName, ...
		persParams.meanScore);
	FileIO.writePersonalParams(userName, 'CA_simpleSMD', persParams);
end