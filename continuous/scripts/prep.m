disp('Fetching references..');
numFiles = length(dir(fullfile(FileIO.PFILTERED,'*.mat')));
for ii = 1:numFiles
	userName = getUserName(ii);
	[monoRefs.(userName), diRefs.(userName)] = FileIO.readRefs(ii);
	testSets.(userName) = FileIO.readTestSet(ii);
	validSets.(userName) = FileIO.readValidationSet(ii);
end
clearvars -except diRefs monoRefs testSets validSets;