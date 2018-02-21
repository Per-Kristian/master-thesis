classdef Runner < handle
	%RUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		db
		user
		imposter
		params
		paramsID
		probeSets
		setType
		monoRefs
		diRefs
		numUsers
		numImps
		fast
	end
	
	methods
		function obj = Runner(user, imposter, params, probeSets, setType, ...
				monoRefs, diRefs, fast)
			obj.db = DBAccess();
			obj.user = user;
			obj.imposter = imposter;
			obj.params = params;
			obj.probeSets = probeSets;
			obj.setType = setType;
			obj.monoRefs = monoRefs;
			obj.diRefs = diRefs;
			obj.numUsers = numel(fieldnames(probeSets));
			obj.numImps = obj.numUsers-1;
			obj.fast = fast;
		end
		
		function run(obj)
			if strcmp(obj.user, 'all')
				obj.paramsID = obj.db.insertParams(obj.params);
				results = obj.allUsers();
				obj.db.insertResults(results, obj.paramsID);
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
				userName = getUserName(currUser);
				monoRef = obj.monoRefs.(userName);
				diRef = obj.diRefs.(userName);
				fprintf('Processing %s..\n', userName);
				currAvgVals = obj.processImposters(currUser,monoRef,diRef);
				[anga, p1] = obj.getANGA(currAvgVals(currUser,:));
				allGenVals(currUser) = anga;
				%Remove ANGA from array.
				currImpVals = currAvgVals;
				currImpVals(currUser, :) = [];
				undetected = obj.countUndetectedImposters(currImpVals);
				% True if all imposters are at some point locked out.
				p2 = undetected == 0;
				category = obj.decideCategory(p1, p2);
				if category == 2 || category == 4
					indices = find(currImpVals(:,1) == -1);
					currImpVals(indices,1) = currImpVals(indices,2);
				end
				allImpVals(lastRow+1:lastRow+obj.numImps)=currImpVals(:,1);
				lastRow = lastRow + obj.numImps;
				% Increase number of users and imposters not detected for 
				% the active category. (+/-) etc.
				results(category,1) = results(category,1) + 1;
				results(category, 4) = results(category, 4) + undetected;
				%results{row, 1} = [ppGenVals; allGenVals(currUser)];
				tempResults{category,1} = ... 
					[tempResults{category,1}; allGenVals(currUser)];
				tempResults{category,2} = ...
					[tempResults{category,2}; currImpVals(:,1)];
				toc
			end
			%Calc total ANIA/ANGA values
			totVals = cellfun(@mean, tempResults);
			results(1:4, 2:3) = totVals;
			results(5,:) = [obj.numUsers, mean(allGenVals), ... 
				mean(allImpVals), sum(results(:,4))];
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
		
		function currAvgVals = processImposters(obj,currUser,monoRef,diRef)
			%userName = getUserName(currUser);
			if strcmp(obj.imposter, 'all')
				currAvgVals = zeros(obj.numUsers,2);
				for currImposter = 1:obj.numUsers
					imposterName = getUserName(currImposter);
					probeSet = obj.probeSets.(imposterName);
					if obj.fast
						[avgActions, trustProgress] = ... 
							obj.fastProcess(currUser, currImposter);
					else
					[avgActions, trustProgress] = ...
						obj.simulate(monoRef, diRef, probeSet);
					end
					%identical = obj.compareToOld(userName, imposterName,avgActions);
					FileIO.writeSingleResult(currUser, currImposter, ...
						obj.params.type, obj.paramsID, ...
						obj.numUsers, trustProgress, avgActions);
					currAvgVals(currImposter,:) = ...
						[avgActions, length(probeSet)];
				end
			else
				probeSet = obj.probeSets.(getUserName(obj.imposter));
				if obj.fast
					obj.fastProcess(monoRef, diRef, probeSet);
				else
					obj.simulate(monoRef, diRef, probeSet);
				end
				currAvgVals = [obj.imposter, length(probeSet)];
			end
		end
		
		function [anga, notLocked] = getANGA(obj, row) %#ok<INUSL>
			%GETANGA Return current user's ANGA. If they were never locked
			%out, notLocked is true.
			if row(1) == -1
				anga = row(2);
				notLocked = true;
			else
				anga = row(1);
				notLocked = false;
			end
		end
		
		function identical = compareToOld(user, imposter, avgActions)
			%COMPARETOOLD Function for debugging. Compares a single result
			%against an older one.
			res = FileIO.readSingleResult(user, imposter, obj.param.type, ...
				obj.paramsID, obj.numUsers, 1);
			identical = avgActions == res;		
		end
		
		function category = decideCategory(obj, p1, p2) %#ok<INUSL>
			%DECIDECLASS Returns which class the result belongs in.
			%	Classes:
			%	(+/+) = 1, (+/-) = 2, (-/+) = 3, (-/-) = 4.
				if p1 && p2
					category = 1;
				elseif p1 && ~p2
					category = 2;
				elseif ~p1 && p2
					category = 3;
				else
					category = 4;
				end
		end
		
		function [num] = countUndetectedImposters(obj, currImpVals) %#ok<INUSL>
			undetected = currImpVals(currImpVals(:,1) == -1, :);
			num = size(undetected,1);
		end
		
		function [avgActions, trustProgress] = fastProcess(obj, currUser, ...
				currImposter)
			%FASTPROCESS Uses pre-calculated scores, and processes all users
			%against themselves and eachother.
			monoCol = 1;
			diCol = 2;
			userName = getUserName(currUser);
			userParams = obj.params;
			if isnan(userParams.lockout)
				storedParams = FileIO.readPersonalParams(userName,persParams.type);
				userParams.lockout = storedParams.threshold;
			end
			imposterName = getUserName(currImposter);
			scores = FileIO.readScores(userName, imposterName, ...
				userParams.type, obj.setType);
			scoresLength = length(scores);
			trustProgress = zeros(length(scores), 1);
			trustModel = TrustModel(userParams);
			for jj = 1:scoresLength
				newTrust = trustModel.alterTrust(scores(jj,monoCol));
				if ~isnan(scores(jj,diCol))
					newTrust = trustModel.alterTrust(scores(jj, diCol));
				end
				trustProgress(jj) = newTrust;
				if newTrust < userParams.lockout
					trustModel.trust = 100;
				end
			end
			avgActions = obj.avgActions(trustProgress, userParams);
		end
		
		function [avgActions,trustProgress] = simulate(obj, ...
				monoRef, diRef, probeSet)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			matcher = Matcher(monoRef, diRef);
			testLength = length(probeSet);
			trustModel = TrustModel(obj.params);
			trustProgress = zeros(testLength, 1);
			prevRow = {[], [], [], []};
			
			for jj = 1:testLength
				currRow = probeSet(jj,:);
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
			avgActions = obj.avgActions(trustProgress, obj.params);
		end
			
		function [monoRef, diRef, probeSet] = fetchSets(obj, user, imposter)
			%FETCHSETS Fetches references and test set for specified user
			%and imposter.
			userName = sprintf('User_%02d', user);
			monoRef = obj.monoRefs.(userName);
			diRef = obj.diRefs.(userName);
			imposterName = sprintf('User_%02d', imposter);
			probeSet = obj.probeSets.(imposterName);
		end
		
		function avg = avgActions(obj, trustProgress, params)
			% AVGACTIONS Calculates the average number of actions before
			% being locked out.
			%	Returns -1 if they are never locked out.
			indices = find(trustProgress < params.lockout);
			
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