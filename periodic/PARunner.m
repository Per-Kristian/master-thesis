classdef PARunner < handle
	%PARUNNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
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
		resultNote
	end
	
	methods
		function obj = PARunner(user, imposter, params, probeSets, setType, ...
				monoRefs, diRefs, fast, resultNote)
			obj.db = DBAccess('PA');
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
			obj.resultNote = resultNote;
		end
		
		function run(obj)
			if strcmp(obj.setType, 'test')
				useDB = true;
				obj.paramsID = obj.db.insertParams(obj.params);
			end
			if strcmp(obj.user, 'all')
				results = obj.allUsers();
				if useDB
					%obj.db.insertResults(results, obj.paramsID, obj.resultNote);
				end
			else
				results = obj.singleUser();
			end
		end
		
		function scores = simulate(obj, monoRef, diRef, probeSet)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself. Public so that
			% scripts can use it to calculate block scores.
			matcher = Matcher(monoRef, diRef);
			probeLength = length(probeSet);
			
			numBlocks = floor(probeLength / obj.params.blockLength);
			blockScores = zeros(numBlocks,1);
			
			for ii = 1:numBlocks
				blockEnd = ii * obj.params.blockLength;
				blockStart = blockEnd - obj.params.blockLength + 1;
				block = probeSet(blockStart:blockEnd, :);
				
				monographs = FeatureExtractor.extractSingleActions(block);
				digraphs = FeatureExtractor.extractDigraphActions(block, true);
				blockScores(ii) = matcher.getBlockScore(monographs, digraphs);
			end
			scores = blockScores(~isnan(blockScores));
		end
	end
	
	methods (Access = private)
		function results = allUsers(obj)
			allImpVals = zeros(obj.numUsers*obj.numImps, 2);
			allGenResults = zeros(obj.numUsers,2);
			tempResults = cell(4,2);
			results = zeros(5,4);
			lastRow = 0; % this is gradually increased in loop.
			
			for currUser = 1:obj.numUsers
				tic
				userName = getUserName(currUser);
				fprintf('Processing %s..\n', userName);
				userResults = obj.processImposters(userName);
				allGenResults(currUser,:) = userResults(currUser,:);
				if allGenResults(currUser,1) == 0
					p1 = true;
				else
					p1 = false;
				end
				%{
				fnmr = currUserRow(1) / currUserRow(2) * 100;
				%Set flag to be true if genuine user was never locked out
				if fnmr == 0
					p1 = true;
				else
					p1 = false;
				end
				%}
				
				%Remove genuine results from array.
				imposterResults = userResults;
				imposterResults(currUser, :) = [];
				undetected = sum(imposterResults(:,1) == 0);
				% True if all imposters are at some point locked out.
				p2 = undetected == 0;
				category = decideCategory(p1, p2);
				%{
				if category == 2 || category == 4
					indices = find(imposterResults(:,1) == -1);
					imposterResults(indices,1) = imposterResults(indices,2);
				end
				%}
				allImpVals(lastRow+1:lastRow+obj.numImps,:)=imposterResults;
				lastRow = lastRow + obj.numImps;
				% Increase number of imposters not detected and users for 
				% the active category. (+/-) etc.
				results(category,1) = results(category,1) + 1;
				results(category, 4) = results(category, 4) + undetected;
				%results{row, 1} = [ppGenVals; allGenVals(currUser)];
				tempResults{category,1} = ... 
					[tempResults{category,1}; allGenResults(currUser,:)];
				tempResults{category,2} = ...
					[tempResults{category,2}; imposterResults];
				toc
			end
			%Calc total FMR and FNMR values
			%totVals = cellfun(@(x) x(:,1)./x(:,2).*100, tempResults);
			%totVals = cellfun(@(x) sum(x(:,1))/sum(x(:,2))*100, tempResults);
			FNMRs = cellfun(@(x) calcPercentageLocked(x), ...
				tempResults(:,1), 'UniformOutput', false);
			FMRs = cellfun(@(x) 100-calcPercentageLocked(x), ...
				tempResults(:,2), 'UniformOutput', false);
			results(1:4, 2) = cell2mat(FNMRs);
			results(1:4, 3) = cell2mat(FMRs);
			results(5,:) = [obj.numUsers, ...
				calcPercentageLocked(allGenResults), ... 
				100-calcPercentageLocked(allImpVals), sum(results(:,4))];
		end
		
		function res = singleUser(obj)
			userName = getUserName(obj.user);
			fprintf('Processing %s..\n', userName);
			res = obj.processImposters(userName);
		end
		
		function userResults = processImposters(obj,userName)
			monoRef = obj.monoRefs.(userName);
			diRef = obj.diRefs.(userName);
			storedParams = FileIO.readPersonalPAParams(userName,'PA', ...
				obj.params);
			lockout = storedParams.meanScore + obj.params.tolerance;
			if strcmp(obj.imposter, 'all')
				userResults = zeros(obj.numUsers,2);
				for currImposter = 1:obj.numUsers
					imposterName = getUserName(currImposter);
					probeSet = obj.probeSets.(imposterName);
					if obj.fast
						scores = FileIO.readPAScores(userName, imposterName, ...
							obj.setType, obj.params);
					else
						scores = obj.simulate(monoRef, diRef, probeSet);
					end
					numBlocks = length(scores);
					timesLocked = sum(scores > lockout);
					userResults(currImposter,:) = [timesLocked, numBlocks];
					%FileIO.writeSingleResult(userName, imposterName, ...
					%	obj.params.type, obj.paramsID, ...
					%	obj.numUsers, trustProgress, avgActions, obj.fast);
				end
			else
				imposterName = getUserName(obj.imposter);
				if obj.fast
					scores = obj.fastProcess(userName, imposterName);
				else
					probeSet = obj.probeSets.(imposterName);
					scores = obj.simulate(monoRef, diRef, probeSet);
				end
				%FileIO.writeSingleResult(userName, imposterName, ...
				%	obj.params.type, obj.paramsID, ...
				%	obj.numUsers, trustProgress, avgActions, obj.fast);
				numBlocks = length(scores);
				timesLocked = sum(scores > lockout);
				userResults = [timesLocked, numBlocks];
			end
		end
		
		function blockScores = fastProcess(obj, userName, ...
				imposterName)
			%FASTPROCESS Uses pre-calculated scores to process an imposter
			%against a user
			userParams = obj.params;
			
			scores = FileIO.readPAScores(userName, imposterName, ...
				userParams.type, obj.setType, obj.params);
		end
		
		%{
		function percentage = calcPercentageLocked(resultArr)
			if ~isempty(resultArr)
				percentage = sum(resultArr(:,1))/sum(resultArr(:,2))*100;
			else
				percentage = [];
			end
		end
		%}

		
		%{
		OLD SIMULATE
		function [fmr, fnmr] = simulate(obj, ...
				monoRef, diRef, probeSet)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			matcher = Matcher(monoRef, diRef);
			testLength = length(probeSet);
			finalRow = testLength-mod(testLength,obj.params.blockLength);
			
			for ii = 1:obj.params.blockLength:finalRow
				lastBlockRow = ii+obj.params.blockLength-1;
				block = probeSet(ii:lastBlockRow, :);
				%digraphs = obj.findNgraphs(block);
				monographs = FeatureExtractor.extractSingleActions(block);
				digraphs = FeatureExtractor.extractDigraphActions(block, true);
				score = matcher.getBlockScore(monographs, digraphs);
			end
		end
		%}
		%{
		function diProbes = findNgraphs(obj, block)
			diProbes = cell(obj.params.blockLength, 6);
			numDiProbes = 0;
			prevRow = {[], [], [], []};
			for ii = 1:obj.params.blockLength
				currRow = block(ii,:);
				if isDigraph(prevRow, currRow)
					diProbes(ii,:) = ...
						FeatureExtractor.createDiProbe(prevRow, currRow);
					numDiProbes = numDiProbes + 1;
				end
				prevRow = currRow;
			end
			diProbes(all(cellfun(@isempty,diProbes),2),:) = [];
		end
		%}
	end
end

