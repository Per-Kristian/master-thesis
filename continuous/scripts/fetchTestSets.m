function testSets = fetchTestSets()
%FETCHTESTSETS Summary of this function goes here
%   Detailed explanation goes here
for ii = 1:57
	userName = sprintf('User_%02d', ii);
	testSets.(userName) = FileIO.readTestSet(ii);
end
end

