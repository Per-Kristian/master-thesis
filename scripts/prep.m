disp('Fetching references..');
numFiles = length(dir(fullfile(FileIO.PFILTERED,'*.mat')));
full = true;
for ii = 1:numFiles
	userName = getUserName(ii);
	[monoRefs.(userName), diRefs.(userName)] = FileIO.readRefs(ii, full);
	diRefSortPP.(userName) = sortrows(diRefs.(userName), 3);
	diRefSortFlight.(userName) = sortrows(diRefs.(userName), 5);
	testSets.(userName) = FileIO.readTestSet(ii);
	validSets.(userName) = FileIO.readValidationSet(ii);
end
clearvars -except diRefs diRefSortFlight diRefSortPP monoRefs testSets validSets;