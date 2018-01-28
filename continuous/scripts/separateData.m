function separateData(user)
%SEPARATEDATA % This script separates user data into 35% training,
%10% validation and the rest for testing.
%	Parameter should be 'all' or an int between 1 and 57 for specific user.
tic
if strcmp('all', user)
	for ii = 1:57
		writeData(ii);
	end
else
	writeData(user);
end
	function writeData(user)
		trainPtn = 0.35;
		validPtn = 0.1;
		validPath = '../../../Data/filtered/validation/';
		testingPath = '../../../Data/filtered/testing/';
		
		fromFile = sprintf('../../../Data/filtered/User_%02d.mat', user);
		keystrokes = importdata(fromFile);
		kslength = length(keystrokes);
		lastTrainingRow = int32(floor(trainPtn*kslength));
		refSubset = keystrokes(1:lastTrainingRow, :);
		createRefs(user, refSubset);
		
		lastValidRow = lastTrainingRow + int32(floor(validPtn*kslength));
		validSubset = keystrokes(lastTrainingRow+1:lastValidRow, :);
		toFile = sprintf(strcat(validPath, 'User_%02d.mat'), user);
		if ~isdir(validPath)
			mkdir(validPath);
		end
		save(toFile, 'validSubset');
		
		testSubset = keystrokes(lastValidRow+1:end, :);
		toFile = sprintf(strcat(testingPath, 'User_%02d.mat'), user);
		if ~isdir(testingPath)
			mkdir(testingPath);
		end
		save(toFile, 'testSubset');
	end
toc
end