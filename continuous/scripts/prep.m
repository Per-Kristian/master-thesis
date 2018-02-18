disp('Fetching references..');
numFiles = length(dir(fullfile(FileIO.PFILTERED,'*.mat')));
for ii = 1:numFiles
	userName = sprintf('User_%02d', ii);
	[monoRefs.(userName), diRefs.(userName)] = FileIO.readRefs(ii);
end
disp('Fetching test sets..');
for ii = 1:numFiles
	userName = sprintf('User_%02d', ii);
	testSets.(userName) = FileIO.readTestSet(ii);
end
clearvars -except diRefs monoRefs testSets;