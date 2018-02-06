disp('Fetching references..');
for ii = 1:57
	userName = sprintf('User_%02d', ii);
	[monoRefs.(userName), diRefs.(userName)] = FileIO.readRefs(ii);
end
disp('Fetching test sets..');
for ii = 1:57
	userName = sprintf('User_%02d', ii);
	testSets.(userName) = FileIO.readTestSet(ii);
end