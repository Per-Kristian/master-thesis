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
%			obj.db = DBAccess();
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
			%obj.paramsID = obj.db.insertParams(obj.params);
			if strcmp(obj.user, 'all')
				results = obj.allUsers();
				%obj.db.insertResults(results, obj.paramsID, obj.resultNote);
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
			lastRow = 0; % this is gradually increased in loop.
			
			for currUser = 1:obj.numUsers
				tic
				userName = getUserName(currUser);
				fprintf('Processing %s..\n', userName);
				currAvgVals = obj.processImposters(userName); % Go through this
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
		
		function singleUser(obj)
			userName = getUserName(obj.user);
			fprintf('Processing %s..\n', userName);
			obj.processImposters(userName);
		end
		
		function currAvgVals = processImposters(obj,userName)
			monoRef = obj.monoRefs.(userName);
			diRefPP = obj.diRefs.(userName);

			if strcmp(obj.imposter, 'all')
				currAvgVals = zeros(obj.numUsers,2);
				for currImposter = 1:obj.numUsers
					imposterName = getUserName(currImposter);
					probeSet = obj.probeSets.(imposterName);
					if obj.fast
						[avgActions, trustProgress] = ...
							obj.fastProcess(userName, imposterName);
					else
						diRefFlight = sortrows(diRefPP, 5);
						[fmr, fnmr] = ...
							obj.simulate(monoRef, diRefPP, diRefFlight, probeSet);
					end
					FileIO.writeSingleResult(userName, imposterName, ...
						obj.params.type, obj.paramsID, ...
						obj.numUsers, trustProgress, avgActions, obj.fast);
					currAvgVals(currImposter,:) = ...
						[avgActions, length(probeSet)];
				end
			else
				imposterName = getUserName(obj.imposter);
				if obj.fast
					[fmr, fnmr] = obj.fastProcess(userName, imposterName);
				else
					probeSet = obj.probeSets.(imposterName);
					diRefFlight = sortrows(diRefPP, 5);
					[fmr,fnmr] = obj.simulate(monoRef,diRefPP,diRefFlight,probeSet);
				end
				%FileIO.writeSingleResult(userName, imposterName, ...
				%	obj.params.type, obj.paramsID, ...
				%	obj.numUsers, trustProgress, avgActions, obj.fast);
				currAvgVals = [obj.imposter, length(obj.probeSets.(imposterName))];
			end
		end
		
		function [fmr, fnmr] = simulate(obj, ...
				monoRef, diRefPP, diRefFlight, probeSet)
			% Simulates genuine behavior or an attack depending on whether
			% or not the imposter parameter is the user itself.
			matcher = Matcher(monoRef, diRefPP, diRefFlight);
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
	end
end

