classdef CombRunner < handle
	%COMBRUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		db
		user
		imposter
		CAParams
		PAParams
		paramsID
		probeSets
		setType
		monoRefs
		diRefs
		numUsers
		numImps
		fast
		resultNote
		systemType
		CAType
	end
	
	methods
		function obj = CombRunner(user, imposter, CAParams, PAParams, ...
				probeSets, setType, monoRefs, diRefs, fast, resultNote, ...
				systemType, CAType)
			obj.db = DBAccess(systemType);
			obj.user = user;
			obj.imposter = imposter;
			obj.CAParams = CAParams;
			obj.PAParams = PAParams;
			obj.probeSets = probeSets;
			obj.setType = setType;
			obj.monoRefs = monoRefs;
			obj.diRefs = diRefs;
			obj.numUsers = numel(fieldnames(probeSets));
			obj.numImps = obj.numUsers-1;
			obj.fast = fast;
			obj.resultNote = resultNote;
			obj.CAType = CAType;
		end
		
		function run(obj)
			if strcmp(obj.user, 'all')
				obj.paramsID = obj.db.insertParams(obj.params);
				results = obj.allUsers();
				obj.db.insertResults(results, obj.paramsID, obj.resultNote);
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
				fprintf('Processing %s..\n', userName);
				currAvgVals = obj.processImposters(userName);
				[anga, p1] = obj.getANGA(currAvgVals(currUser,:));
				allGenVals(currUser) = anga;
				%Remove ANGA from array.
				currImpVals = currAvgVals;
				currImpVals(currUser, :) = [];
				undetected = obj.countUndetectedImposters(currImpVals);
				% True if all imposters are at some point locked out.
				p2 = undetected == 0;
				category = decideCategory(p1, p2);
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
		
		function singleUser(obj)
			userName = getUserName(obj.user);
			fprintf('Processing %s..\n', userName);
			tic
			currAvgVals = obj.processImposters(userName);
			toc
		end
		
		function currAvgVals = processImposters(obj,userName)
			sets.monoRef = obj.monoRefs.(userName);
			sets.diRef = obj.diRefs.(userName);
			storedPAParams = FileIO.readPersonalPAParams(userName,'PA', ...
				obj.PAParams);
			PALockout = storedPAParams.meanScore + obj.PAParams.tolerance;
			CAuserParams = obj.CAParams;
			
			if isnan(CAuserParams.lockout)
				storedCAParams = FileIO.readPersonalParams(userName,obj.CAType);
				CAuserParams.lockout = storedCAParams.threshold;
			end
			
			if strcmp(obj.imposter, 'all')
				currAvgVals = zeros(obj.numUsers,2);
				for currImposter = 1:obj.numUsers
					imposterName = getUserName(currImposter);
					sets.probeSet = obj.probeSets.(imposterName);
					if obj.fast
						[avgActions, trustProgress] = obj.fastProcess(sets, ... 
							userName, imposterName, CAUserParams, PALockout);
					else
					[avgActions, trustProgress] = obj.simulate(sets, ... 
						CAUserParams, PALockout);
					end
					%FileIO.writeSingleResult(userName, imposterName, ...
					%	obj.systemType, obj.paramsID, ...
					%	obj.numUsers, trustProgress, avgActions, obj.fast);
					currAvgVals(currImposter,:) = [avgActions, length(sets.probeSet)];
				end
			else
				imposterName = getUserName(obj.imposter);
				sets.probeSet = obj.probeSets.(imposterName);
				if obj.fast
					[avgActions, trustProgress] = ...
					obj.fastProcess(sets, userName, imposterName, CAUserParams, ...
							PALockout);
				else
					[avgActions, trustProgress] = ...
					obj.simulate(sets, CAuserParams, PALockout);
				end
				%FileIO.writeSingleResult(userName, imposterName, ...
				%	obj.systemType, obj.paramsID, ...
				%	obj.numUsers, trustProgress, avgActions, obj.fast);
				currAvgVals = [obj.imposter, avgActions, ...
					length(obj.probeSets.(imposterName))];
			end
		end
		
		function [num] = countUndetectedImposters(obj, currImpVals) %#ok<INUSL>
			undetected = currImpVals(currImpVals(:,1) == -1, :);
			num = size(undetected,1);
		end
		
		function [avgActions, trustProgress] = fastProcess(obj, sets, ...
				userName, imposterName, CAUserParams, PALockout)
			
			CAScores = FileIO.readScores(userName, imposterName, ...
				obj.CAType, obj.setType);
			CAScoresLength = length(CAScores);
			trustProgress = NaN(length(CAScores), 2);
			trustModel = TrustModel(CAUserParams);
			lastProcessed = 0;
			blockSets.monoRef = sets.monoRef;
			blockSets.diRef = sets.diRef;
			matcher = Matcher(sets.monoRef, sets.diRef);
			%indLastFullBlock = CAScoresLength-obj.PAParams.blockLength;
			%while lastProcessed <= indLastFullBlock
			while lastProcessed < CAScoresLength
				blockStart = lastProcessed + 1;
				blockEnd = lastProcessed + obj.PAParams.blockLength;
				blockSets.CAScores = CAScores(blockStart:blockEnd, :);
				blockSets.rawProbe = sets.probeSet(blockStart:blockEnd, :);
				
				blockTrustProg = fastBlockProcess(blockSets, trustModel, ...
					CAUserParams.lockout, PALockout, matcher);
				
				lastProcessed = lastProcessed + size(blockTrustProg, 1);
				trustProgress(blockStart:lastProcessed,:) = blockTrustProg;
			end
			avgActions = obj.avgActions(trustProgress, CAuserParams);
			
			%{
			for ii = 1:numBlocks
				blockEnd = ii * obj.PAParams.blockLength;
				blockStart = blockEnd - obj.PAParams.blockLength + 1;
				CABlock = CAScores(blockStart:blockEnd, :);
				CABlockTrustProgress = fastCAProcess(CABlock, trustModel, ...
					CAUserParams.lockout);
				trustProgress(blockStart:blockEnd,1) = CABlockTrustProgress;
				if CABlockTrustProgress(end) >= CAUserParams.lockout
					newTrust = ...
						trustModel.influence(PAScores(ii), obj.combParams.influence);
					if newTrust < CAUserParams.lockout
						trustModel.resetTrust();
					end
				end
			end
			
			
			kk = numBlocks * obj.PAParams.blockLength + 1;
			while(kk <= CAScoresLength)
				newTrust = trustModel.alterTrust(CAScores(kk, monoCol));
			end
			avgActions = obj.avgActions(trustProgress, CAuserParams);
			%}
		end
		
		function blockTrustProgress = fastBlockProcess(obj, sets, ...
				trustModel, CALockout, PALockout, matcher)
			monoCol = 1;
			diCol = 2;
			
			blockLength = size(sets.CAScores,1);
			blockTrustProgress = NaN(blockLength, 2);
			for ii = 1:blockLength
				newTrust = trustModel.alterTrust(sets.CAScores(ii,monoCol));
				if ~isnan(sets.CAScores(ii,diCol))
					newTrust = trustModel.alterTrust(sets.CAScores(ii, diCol));
				end
				blockTrustProgress(ii) = newTrust;
				if newTrust < CALockout
					trustModel.resetTrust();
					blockTrustProgress = blockTrustProgress(1:ii,:);
					return
				end
			end
			
			if blockLength == obj.PAParams.blockLength
				monographs = FeatureExtractor.extractSingleActions(sets.raw);
				digraphs = FeatureExtractor.extractPAngraphs(sets.raw, true);
				blockScore = matcher.getBlockScore(monographs, digraphs);
				newTrust = trustModel.influence(blockScore, ...
					obj.PAParams.influenceType, PALockout);
				blockTrustProgress(blockLength,2) = newTrust;
				if newTrust < CALockout
					trustModel.resetTrust();
				end
			end
		end
		%{
			This function is flawed, as it does not reset blocks when locked out
			by the CA system.
			
		function [avgActions, trustProgress] = fastProcess(obj, userName, ...
				imposterName, CAUserParams, PALockout)
			%FASTPROCESS Uses pre-calculated scores to process an imposter
			%against a user
			monoCol = 1;
			diCol = 2;
			
			CAScores = FileIO.readScores(userName, imposterName, ...
				obj.CAType, obj.setType);
			PAScores = FileIO.readPAScores(userName, imposterName, ...
							obj.setType, obj.PAParams);
						
			CAScoresLength = length(CAScores);
			numBlocks = length(PAScores);
			trustProgress = NaN(length(CAScores), 2);
			trustModel = TrustModel(CAUserParams);
			
			for ii = 1:numBlocks
				blockEnd = ii * obj.PAParams.blockLength;
				blockStart = blockEnd - obj.PAParams.blockLength + 1;
				CABlock = CAScores(blockEnd:blockStart, :);
				CABlockTrustProgress = fastCAProcess(CABlock, trustModel, ...
					CAUserParams.lockout);
				trustProgress(blockStart:blockEnd,1) = CABlockTrustProgress;
				if CABlockTrustProgress(end) >= CAUserParams.lockout
					newTrust = ...
						trustModel.influence(PAScores(ii), obj.combParams.influence);
					if newTrust < CAUserParams.lockout
					trustModel.resetTrust();
				end
				
			end
			
			kk = numBlocks * obj.PAParams.blockLength + 1;
			while(kk <= CAScoresLength)
				newTrust = trustModel.alterTrust(CAScores(kk, monoCol));
			end
			avgActions = obj.avgActions(trustProgress, CAuserParams);
		end
		
		
		function CAblockTrustProgress = fastCAProcess(block, trustModel, lock)
			blockLength = length(block);
			CAblockTrustProgress = NaN(blockLength, 1);
			for ii = 1:blockLength
				newTrust = trustModel.alterTrust(CAScores(ii,monoCol));
				if ~isnan(CAScores(ii,diCol))
					newTrust = trustModel.alterTrust(CAScores(ii, diCol));
				end
				CAblockTrustProgress(ii) = newTrust;
				if newTrust < lock
					trustModel.resetTrust();
				end
			end
		end
		%}
		
		function [avgActions,trustProgress] = simulate(obj, ...
				monoRef, diRef, probeSet)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			matcher = Matcher(monoRef, diRef);
			probeSetLength = length(probeSet);
			trustModel = TrustModel(obj.params);
			trustProgress = NaN(probeSetLength, 2);
			prevRow = {[], [], [], []};
			
			numBlocks = floor(probeSetLength / obj.params.blockLength);
			blockScores = zeros(numBlocks,1);
			
			for ii = 1:numBlocks
				blockEnd = ii * obj.params.blockLength;
				blockStart = blockEnd - obj.params.blockLength + 1;
				blockDiProbes = cell(obj.params.blockLength, 6);
				numDiProbes = 0;
				for jj = blockStart:blockEnd
					currRow = probeSet(jj,:);
					
					score = matcher.getSimpleMonoScore(currRow(1:2));
					newTrust = trustModel.alterTrust(score);
					% Check previous row
					if isDigraph(prevRow, currRow)
						diProbe = FeatureExtractor.createDiProbe(prevRow, currRow);
						score = matcher.getSimpleDiScore(diProbe);
						newTrust = trustModel.alterTrust(score);
						%Store the probe for use in periodic authentication.
						numDiProbes = numDiProbes + 1;
						blockDiProbes(numDiProbes, :) = diProbe;
					end
					trustProgress(jj,1) = newTrust;
					% Reset trust level to 100 if it has dropped below lockout.
					if newTrust < obj.params.lockout
						trustModel.resetTrust();
					end
					prevRow = currRow;
				end
				% Convert blockDiProbes to a single block probe.
				% Progress: was going to impl. FE.diProbesToBlockProbe
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
					avg = mean(diff([0; indices; size(trustProgress, 1)]));
				end
			end
		end
	end
end

