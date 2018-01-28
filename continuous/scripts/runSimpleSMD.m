function runSimpleSMD(user, genOrAll)
%Expects either an integer or 'all'. Runs the authentication system with
%either a specific user or all users, specifically using simple Scaled 
%Manhattan Distance based on mean and standard deviation.
%	The user parameter is expected to be an int between 1 and 57 for a
%	specific user, or 'all' for analyzing performance on all users.
%	The genOrImp parameter is expected to be 'gen' for testing with genuine
%	data only, or 'imp' for testing with all imposters.

tic
params.rwrdThreshold = 2;
params.width = 0.35;
params.maxRwrd = 1;
params.maxPen = 1;
params.singleOccPen = 3;
params.missingPen = 3.3;
params.lockout = 90;

if strcmp('all', user)
	for ii = 1:57
		run(ii, genOrAll);
	end
else
	run(user, genOrAll);
end

	function run(user, genOrAll)
			if strcmp('gen', genOrAll)
			simulate(user, user);
		elseif strcmp('all', genOrAll)
			for imposter = 1:57
				simulate(user, imposter);
			end
		end
	end

	function simulate(user, imposter)
		testPath = '../../../Data/filtered/testing/';
		resPath = '../../../Data/results/simple_smd/';
		
		matcher = Matcher;
		[monoRef, diRef] = fetchRef(user);
		fromFile = sprintf(strcat(testPath, 'User_%02d.mat'), imposter);
		testSet = importdata(fromFile);
		
		matcher.monoRef = monoRef;
		matcher.diRef = diRef;
		testLength = length(testSet);
		trustModel = TrustModel(params);
		trustProgress = zeros(testLength, 1, 'int8');
		for jj = 1:testLength
			monoProbe = testSet(jj, 1:2);
			score = matcher.getSimpleMonoScore(monoProbe);
			% Check previous row
			newTrust = trustModel.alterTrust(score);
			trustProgress(jj) = newTrust;
		end
		
		userResFolder = sprintf(strcat(resPath, 'User_%02d/'), user);
		impFolder = sprintf(strcat(userResFolder, 'User_%02d/'), imposter);
		if ~isdir(impFolder)
			mkdir(impFolder);
		end
		toFile = strcat(impFolder, 'trustProgress.mat');
		save(toFile, 'trustProgress');
	end
toc
end