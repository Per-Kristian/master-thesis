function runSimpleSMD(user, genOrAll)
%Expects either an integer or 'all'. Runs the authentication system with
%either a specific user or all users, specifically using simple Scaled 
%Manhattan Distance based on mean and standard deviation.
%	The user parameter is expected to be an int between 1 and 57 for a
%	specific user, or 'all' for analyzing performance on all users.
%	The genOrImp parameter is expected to be 'gen' for testing with genuine
%	data only, or 'imp' for testing with all imposters.


if strcmp('all', user)
	for ii = 1:57
		run(ii, genOrAll);
	end
else
	run(user, genOrAll);
end

	function run(user, genOrAll)
		
		if strcmp('gen', genOrAll)
			test(user, user);
		elseif strcmp('all', genOrAll)
			for imposter = 1:57
				test(user, imposter);
			end
		end
	end

	function test(user, imposter)
		testPath = '../../../Data/filtered/testing/';
		resPath = '../../../Data/results/simple_smd/';
		threshold = 2;
		width = 0.35;
		maxRwrd = 1;
		maxPen = 1;
		singleOccPen = 3;
		missingPen = 3.3;
		
		matcher = Matcher;
		[monoRef, diRef] = fetchRef(user);
		fromFile = sprintf(strcat(testPath, 'User_%02d.mat'), user);
		testSet = importdata(fromFile);
		
		matcher.monoRef = monoRef;
		matcher.diRef = diRef;
		testLength = length(testSet);
		trustModel = TrustModel(threshold, width, maxRwrd, maxPen, ...
			singleOccPen, missingPen);
		trustProgress = zeros(testLength+1, 'int8');
		trustProgress(1) = 100;
		for jj = 1:testLength
			probe = testSet(jj, 1:2);
			score = matcher.getSimpleMonoScore(probe);
			newTrust = trustModel.alterTrust(score);
			trustProgress(jj+1) = newTrust;
		end
		userResFolder = sprintf(strcat(resPath, 'User_%02d'), user);
		if ~exists(userResFolder, 'dir')
			mkdir(userResFolder);
		end
		toFile = strcat(userResFolder, 'progress');
		save(toFile, 'trustProgress');
		toFile = sprintf(strcat(resPath, 'User_%02d.mat'), user);
		save(toFile, 'testSubset');
	end
end