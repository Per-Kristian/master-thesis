function separateData(user)
%SEPARATEDATA % This script separates user data into 35% training,
%10% validation and the rest for testing.
%	Parameter should be 'all' or an int between 1 and 57 for specific user.
disp("Separating data..");
tic
if strcmp('all', user)
	numFiles = length(dir(fullfile(FileIO.PFILTERED,'*.mat')));
	for ii = 1:numFiles
		writeData(ii);
	end
else
	writeData(user);
end
	function writeData(user)
		trainPtn = 0.35;
		validPtn = 0.1;
		
		keystrokes = FileIO.readFiltered(user);
		kslength = length(keystrokes);
		lastTrainingRow = int32(floor(trainPtn*kslength));
		refSubset = keystrokes(1:lastTrainingRow, :);
		createRefs(user, refSubset);
		
		lastValidRow = lastTrainingRow + int32(floor(validPtn*kslength));
		validSubset = keystrokes(lastTrainingRow+1:lastValidRow, :);
		FileIO.writeValidationSet(user, validSubset);
		
		testSubset = keystrokes(lastValidRow+1:end, :);
		FileIO.writeTestSet(user, testSubset);
	end
toc
end