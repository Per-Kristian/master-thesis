params.rwrdThreshold = 1.85;
params.width = 0.28;
params.maxRwrd = 1;
params.maxPen = 1;
params.singleOccScore = 3;
params.missingScore = 3.3;
params.type = 'simpleSMD';
setType = 'validation';
minimumThreshold = 80;

numUsers = FileIO.countScoreUserDirs(params.type, setType);
prevRow = {[], [], [], []};
monoCol = 1;
diCol = 2;
for ii = 1:numUsers
	userName = getUserName(ii);
	scores = FileIO.readScores(userName, userName, params.type, setType);
	scoresLength = length(scores);
	trustProgress = zeros(length(scores), 1);
	trustModel = TrustModel(params);
	for jj = 1:scoresLength
		newTrust = trustModel.alterTrust(scores(jj,monoCol));
		% Check previous row
		if ~isnan(scores(jj,diCol))
			newTrust = trustModel.alterTrust(scores(jj, diCol));
		end
		trustProgress(jj) = newTrust;
	end
	% Save the lowest score as a personal threshold in a params struct, in
	% case I implement completely personal parameters in the future.
	persParam.threshold = max(minimumThreshold, min(trustProgress));
	fprintf("Storing %s's threshold: %d\n", userName, persParam.threshold);
	FileIO.writePersonalParams(userName, params.type, persParam);
end