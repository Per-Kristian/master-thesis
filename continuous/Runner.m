classdef Runner
	%RUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	methods (Static)
		function run(user, imposter, params)
			if strcmp(user, 'all')
				Runner.allUsers(imposter, params)
			else
				Runner.singleUser(user, imposter, params);
			end
		end
		
		function allUsers(imposter, params)
			for currUser = 1:57
				if strcmp(imposter, 'all')
					for currImposter = 1:57
						Runner.simulate(currUser, ... 
							currImposter, params);
					end
				else
					Runner.simulate(currUser, imposter, params);
				end
			end
		end
		
		function singleUser(user, imposter, params)
			if strcmp(imposter, 'all')
				for currImposter = 1:57
					Runner.simulate(user, currImposter, params);
				end
			else
				Runner.simulate(user, imposter, params);
			end
		end
		
		function simulate(user, imposter, params)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			testPath = 'Data/filtered/testing/';
			
			matcher = Matcher;
			[monoRef, diRef] = fetchRef(user);
			fromFile = sprintf(strcat(testPath,'User_%02d.mat'), imposter);
			testSet = importdata(fromFile);
			
			matcher.monoRef = monoRef;
			matcher.diRef = diRef;
			testLength = length(testSet);
			trustModel = TrustModel(params);
			trustProgress = zeros(testLength, 1);
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
			
			avgActions = Runner.avgActions(trustProgress);
			% todo: Write to params table here? Send params.type to
			% fileIO?
			FileIO.writeResult(user, imposter, params, ...
				trustProgress, results);
			
		end
			
		function avg = avgActions(trustProgress)
			% AVGACTIONS Calculates the average number of actions before
			% being locked out.
			%	Returns NaN if they are never locked out. Should be
			%	transformed to NULL in database.
			indices = find(trustProgress < 90);
			if length(indices) == 1
				avg = indices(1);
			else
				avg = mean(diff([0; indices]));
			end
		end
	end
end

