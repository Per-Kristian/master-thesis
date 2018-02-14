classdef Runner < handle
	%RUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		db
		user
		imposter
		params
		paramsID
		testSets
		monoRefs
		diRefs
		numUsers
		numImps
	end
	
	methods
		function obj = Runner(user, imposter, params, testSets,...
				monoRefs, diRefs)
			obj.db = DBAccess();
			obj.paramsID = obj.db.insertParams(params);
			obj.user = user;
			obj.imposter = imposter;
			obj.params = params;
			obj.testSets = testSets;
			obj.monoRefs = monoRefs;
			obj.diRefs = diRefs;
			obj.numUsers = numel(fieldnames(testSets));
			obj.numImps = obj.numUsers-1;
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
		function results = allUsers(obj)
			allImpVals = zeros(obj.numUsers*obj.numImps, 1);
			allGenVals = zeros(obj.numUsers,1);
			tempResults = cell(4,2);
			
			results = zeros(5,4);
			% lastRow is gradually increased in loop.
			lastRow = 0;
			for currUser = 1:obj.numUsers
				tic
				fprintf('Processing user %d..\n', currUser);
				currAvgVals = zeros(obj.numUsers,2);
				if strcmp(obj.imposter, 'all')
					for currImposter = 1:obj.numUsers
						[avgActions, trustProgress] = ...
							obj.simulate(currUser, currImposter);
						currAvgVals(currImposter,:) = ...
							[avgActions, length(trustProgress)];
						FileIO.writeSingleResult(currUser, currImposter, ... 
							obj.params.type, obj.paramsID, ...
							obj.numUsers, trustProgress, avgActions);
					end
				else
					obj.simulate(currUser, obj.imposter);
				end
				% Store current user's ANGA. If they weren't locked out,
				% use total number of keystrokes tested.
				if currAvgVals(currUser,1) == -1
					allGenVals(currUser) = currAvgVals(currUser,2);
					p1 = true;
				else
					allGenVals(currUser) = currAvgVals(currUser,1);
					p1 = false;
				end
				%Remove ANGA from array.
				currImpVals = currAvgVals;
				currImpVals(currUser, :) = [];
				impsNotLocked = currImpVals(currImpVals(:,1) == -1, :);
				% True if all imposters are at some point locked out.
				p2 = isempty(impsNotLocked);
				
				if p1 && p2
					row = 1;
				elseif p1 && ~p2
					row = 2;
					indices = find(currImpVals(:,1) == -1);
					currImpVals(indices,1) = currImpVals(indices,2);
				elseif ~p1 && p2
					row = 3;
				else
					row = 4;
					indices = find(currImpVals(:,1) == -1);
					currImpVals(indices,1) = currImpVals(indices,2);
				end
				
				impND = size(impsNotLocked,1);
				allImpVals(lastRow+1:lastRow+obj.numImps) = currImpVals(:,1);
				lastRow = lastRow + obj.numImps;
				% Increase number of users and imposters not detected for 
				% the active category. (+/-)
				results(row,1) = results(row,1) + 1;
				results(row, 4) = results(row, 4) + impND;
				%results{row, 1} = [ppGenVals; allGenVals(currUser)];
				tempResults{row,1} = ... 
					[tempResults{row,1}; allGenVals(currUser)];
				tempResults{row,2} = [tempResults{row,2}; currImpVals(:,1)];
				toc
			end
			%Calc total ANIA/ANGA values
			totVals = cellfun(@mean, tempResults);
			results(1:4, 2:3) = totVals;
			results(5,:) = [obj.numUsers, mean(allGenVals), ... 
				mean(allImpVals), sum(results(:,4))];
			obj.db.insertResults(results, obj.paramsID);
		end
		
		function [avgActions, trustProgress] = singleUser(obj)
			if strcmp(obj.imposter, 'all')
				for currImposter = 1:obj.numUsers
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
			matcher = Matcher;
			userName = sprintf('User_%02d', user);
			monoRef = obj.monoRefs.(userName);
			diRef = obj.diRefs.(userName);
			imposterName = sprintf('User_%02d', imposter);
			testSet = obj.testSets.(imposterName);
			
			matcher.monoRef = monoRef;
			matcher.diRef = diRef;
			testLength = length(testSet);
			trustModel = TrustModel(obj.params);
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
			indices = find(trustProgress < obj.params.lockout);
			
			if isempty(indices)
				avg = -1;
			else
				% Only include the keystrokes after the last lockout if it
				% will pull the average number of actions UP.
				avgWithoutEnd = mean(diff([0; indices]));
				endLength = length(trustProgress)-indices(end);
				if endLength <= avgWithoutEnd
					avg = mean(diff([0; indices]));
				else
					avg = mean(diff([0; indices; length(trustProgress)]));
				end
			end
		end
	end
end