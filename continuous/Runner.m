classdef Runner < handle
	%RUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		db
		user
		imposter
		params
		paramsID
	end
	
	methods
		function obj = Runner(user, imposter, params)
			obj.db = DBAccess();
			obj.paramsID = db.insertParams(params);
			obj.user = user;
			obj.imposter = imposter;
		end
		
		function run(obj)
			if strcmp(obj.user, 'all')
				obj.allUsers();
			else
				obj.singleUser();
			end
		end
	end
	methods (Access = private)
		function allUsers(obj)
			allImpVals = zeros(57*56, 1);
			allGenVals = zeros(57,1);
			
			
			% lastRow is gradually increased in loop.
			lastRow = 0;
			for currUser = 1:57
				currAvgVals = zeros(57);
				if strcmp(obj.imposter, 'all')
					for currImposter = 1:57
						[avgActions, trustProgress] = ...
							obj.simulate(currUser, currImposter);
						currAvgVals(currImposter) = avgActions;
						%FileIO.writeSingResult(obj.user, currImposter, ... 
						%	obj.paramsID, trustProgress);
						
						% Store all avgActions in an array.
						% Take note of genuine run, use currUser.
						%
					end
				else
					obj.simulate(currUser, obj.imposter);
				end
				% Store current user's ANGA.
				allGenVals(currUser) = currAvgVals(currUser);
				currAvgVals(currUser) = [];
				allImpVals(lastRow+1:lastRow+56) = currAvgVals;
				lastRow = lastRow + 56;
			end
			
		end
		
		function [avgActions, trustProgress] = singleUser(obj)
			if strcmp(obj.imposter, 'all')
				for currImposter = 1:57
					[avgActions, trustProgress] = ... 
						obj.simulate(obj.user, currImposter);
				end
			else
				[avgActions, trustProgress] = ... 
					obj.simulate(obj.user, obj.imposter);
			end
		end
		
		function [avgActions,trustProgress] = simulate(obj, user, imposter)
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
			trustModel = TrustModel(obj.paramsID);
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
				if newTrust < obj.params.lockout
					trustModel.trust = 100;
				end
				prevRow = currRow;
			end
			avgActions = obj.avgActions(trustProgress);
		end
			
		function avg = avgActions(obj, trustProgress)
			% AVGACTIONS Calculates the average number of actions before
			% being locked out.
			%	Returns -1 if they are never locked out.
			indices = find(trustProgress < 90);
			if length(indices) == 1
				avg = indices(1);
			elseif isempty(indices)
				avg = -1;
			else
				avg = mean(diff([0; indices]));
			end
		end
	end
end