classdef Runner
	%RUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	methods (Static)
		function run(user, imposter, params, version)
			if strcmp(user, 'all')
				Runner.allUsers(genOrAll, params, version)
			else
				Runner.singleUser(user, imposter, params, version);
			end
		end
		
		function allUsers(imposter, params, version)
			for currUser = 1:57
				if strcmp(imposter, 'all')
					for currImposter = 1:57
						Runner.simulate(currUser, ... 
							currImposter, params, version);
					end
				else
					Runner.simulate(currUser, imposter, params, version);
				end
			end
		end
		
		function singleUser(user, imposter, params, version)
			if strcmp(imposter, 'all')
				for currImposter = 1:57
					Runner.simulate(user, currImposter, params, version);
				end
			else
				Runner.simulate(user, imposter, params, version);
			end
		end
		
		function simulate(user, imposter, params, version)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			testPath = 'Data/filtered/testing/';
			resPath = strcat('Data/results/', version, '/');
			
			matcher = Matcher;
			[monoRef, diRef] = fetchRef(user);
			fromFile = sprintf(strcat(testPath,'User_%02d.mat'), imposter);
			testSet = importdata(fromFile);
			
			matcher.monoRef = monoRef;
			matcher.diRef = diRef;
			testLength = length(testSet);
			trustModel = TrustModel(params);
			trustProgress = zeros(testLength, 1);
			
			% First check the first monograph, as it cannot be the second
			% key of a digraph.
			%{
			probe = testSet(1,:);
			score = matcher.getSimpleMonoScore(probe(1:2));
			newTrust = trustModel.alterTrust(score);
			trustProgress(1) = newTrust;
			%}
			
			prevRow = {[], [], [], []};
			for jj = 1:testLength
				currRow = testSet(jj,:);
				score = matcher.getSimpleMonoScore(currRow(1:2));
				newTrust = trustModel.alterTrust(score);
				% Check previous row
				if strcmp(prevRow{3}, currRow{1}) && ...
						prevRow{4} < FeatureExtractor.maxFlightTime
					diProbe = ...
						FeatureExtractor.createDiProbe(prevRow, currRow);
					score = matcher.getSimpleDiScore(diProbe);
					newTrust = trustModel.alterTrust(score);
				end
				trustProgress(jj) = newTrust;
				% Reset trust level to 100 if it has dropped below lockout.
				if newTrust < params.lockout
					trustModel.trust = 100;
				end
				prevRow = currRow;
			end
			
			userResFolder = sprintf(strcat(resPath, 'User_%02d/'), user);
			impFolder = sprintf(strcat(userResFolder, 'User_%02d/'), imposter);
			if ~isdir(impFolder)
				mkdir(impFolder);
			end
			toFile = strcat(impFolder, 'trustProgress.mat');
			save(toFile, 'trustProgress');
		end
	end
end

