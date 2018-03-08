function separateData(user, full)
%SEPARATEDATA % This script separates user data into 35% training,
%10% validation and the rest for testing.
%	user should be 'all' or an int between 1 and 57 for specific user.
%	full should be FALSE if only mean and stdv is needed in references.
disp("Separating data..");
tic
if strcmp('all', user)
	numFiles = length(dir(fullfile(FileIO.PFILTERED,'*.mat')));
	for ii = 1:numFiles
		writeData(ii, full);
	end
else
	writeData(user, full);
end
	function writeData(user, full)
		trainPtn = 0.35;
		validPtn = 0.1;
		maxTrain = 20000;
		
		keystrokes = FileIO.readFiltered(user);
		kslength = length(keystrokes);
		lastTrainingRow = int32(floor(trainPtn*kslength));
		if lastTrainingRow > maxTrain
			lastTrainingRow = maxTrain;
		end
		refSubset = keystrokes(1:lastTrainingRow, :);
		createRefs(user, refSubset, full);
		
		lastValidRow = lastTrainingRow + int32(floor(validPtn*kslength));
		validSubset = keystrokes(lastTrainingRow+1:lastValidRow, :);
		FileIO.writeValidationSet(user, validSubset);
		
		testSubset = keystrokes(lastValidRow+1:end, :);
		FileIO.writeTestSet(user, testSubset);
	end
toc
end