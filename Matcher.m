classdef Matcher < handle
	%MATCHER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		monoRef
		diRef
		diRefPP
		diRefRP
	end
	
	methods
		%{
		function obj = Matcher()
			% do nothing
		end
		%}
		
		function obj = Matcher(varargin)
			%MATCHER Construct an instance of this class
			%   Expects references formatted by FeatureExtractor.
			obj.monoRef = varargin{1};
			obj.diRef = varargin{2};
			obj.diRefPP = sortrows(obj.diRef, 3);
			obj.diRefRP = sortrows(obj.diRef, 5);
			%{
			if nargin>2
				obj.diRefRP = varargin{3};
			end
			%}
		end
		
		function score = getMonoScores(obj, probe)
			[minDist, meanDist, maxDist] = monoSMD(obj, probe);
			score = 1-(meanDist-minDist)/(maxDist-minDist);
		end
		
		function scores = preCalcSimpleSMDScores(obj,probeSet)
			setLength = length(probeSet);
			scores = NaN(setLength,2);
			prevRow = {[], [], [], []};
			for jj = 1:setLength
				currRow = probeSet(jj,:);
				scores(jj,1) = obj.getSimpleMonoScore(currRow(1:2));
				if strcmp(prevRow{3}, currRow{1}) && ...
						prevRow{4} < FeatureExtractor.maxFlightTime
					diProbe = ...
						FeatureExtractor.createDiProbe(prevRow, currRow);
					scores(jj,2) = obj.getSimpleDiScore(diProbe);
				end
				prevRow = currRow;
			end
		end
		
		function score = getSimpleMonoScore(obj, probe)
			index = find(strcmp(obj.monoRef(:,1), probe{1}));
			%If there are no occurrences in reference, return -2
			if isempty(index)
				score = -2;
			else
				refRow = obj.monoRef(index, :);
				% If there is only one occurrence in the reference, there
				% exists no standard deviation, and distance can't be
				% calculated. Return -1 to indicate this.
				if length(refRow{2}) == 1
					score = -1;
				else
					refMean = refRow{3};
					refStd = refRow{4};
					diff = abs(probe{2}-refMean);
					if diff == 0
						diff = 0.0001;
					end
					if refStd == 0
						refStd = 0.1;
					end
					score = diff/refStd;
				end
			end
		end
		
		%{
		function score = getSimpleDiScore(obj, probe)
			index = find(strcmp(obj.diRef(:,1), probe{1}) & ...
				strcmp(obj.diRef(:,2), probe{2}));
			
			if isempty(index)
				score = -2;
			else
				refRow = obj.diRef(index, :);	
				if length(refRow{3}) == 1
					score = -1;
				else
					latMeans = cell2mat(refRow(3:6));
					latStds = cell2mat(refRow(7:10));
					dists = NaN(1,4);
					for ii = 1:4
						diff = abs(probe{ii+2}-latMeans(ii));
						% Handle edge cases where the feature matches the exact
						% expected value. Also, handle cases where stdv is 0.
						if diff == 0
							diff = 0.0001;
						end
						if latStds(ii) == 0
							latStds(ii) = 0.1;
						end
						dists(ii) = diff/latStds(ii);
					end
					score = mean(dists);
				end
			end
		end
		%}
		
		function score = getSimpleDiScore(obj, probe)
			index = find(strcmp(obj.diRef(:,1), probe{1}));
			
			if isempty(index)
				score = -2;
			else
				refRow = obj.diRef(index, :);	
				if length(refRow{3}) == 1
					score = -1;
				else
					latMeans = cell2mat(refRow(3:6));
					latStds = cell2mat(refRow(7:10));
					dists = NaN(1,4);
					for ii = 1:4
						diff = abs(probe{ii+2}-latMeans(ii));
						% Handle edge cases where the feature matches the exact
						% expected value. Also, handle cases where stdv is 0.
						if diff == 0
							diff = 0.0001;
						end
						if latStds(ii) == 0
							latStds(ii) = 0.1;
						end
						dists(ii) = diff/latStds(ii);
					end
					score = nanmean(dists);
				end
			end
		end
		
		function score = getBlockScore(obj, monographs, digraphs)
			sharedMonos = obj.getSharedMonos(monographs);
			sharedDis = obj.getSharedDigraphs(digraphs);
			
			numShared.monosUnique = size(sharedMonos.probe,1);
			numShared.monosTotal = sum(cellfun(@(x) length(x), ... 
				sharedMonos.probe(:, 2)));
			if numShared.monosTotal == 0
				score = 99;
			else
				numShared.diPPsTotal = sum(cellfun(@(x) length(x(~isnan(x))), ... 
					sharedDis.probe(:, 11)));
				numShared.diRPsTotal = sum(cellfun(@(x) length(x(~isnan(x))), ... 
					sharedDis.probe(:, 13)));
				numShared.disUnique = size(sharedDis.probe,1);
				
				weights.monos = numShared.monosTotal;
				weights.diPPs = numShared.diPPsTotal / 2;
				weights.diRPs = numShared.diRPsTotal / 2;
				
				means.monos = [sharedMonos.ref(:,[1 3]), sharedMonos.probe(:,3)];
				means.diPPs = [sharedDis.ref(:,[1 3]), sharedDis.probe(:,3)];
				means.diRPs = [sharedDis.ref(:,[1 5]), sharedDis.probe(:,5)];
				
				absDist = obj.getAbsoluteDistance(means, numShared, weights);
				relDist = obj.getRelativeDistance(means, numShared, weights);
				
				score = absDist + relDist;
			end
		end
		%{
		function score = getBlockScoreMonosOnly(obj, monographs)
			sharedMonos = obj.getSharedMonos(monographs);
			
			%numShared.monos = size(sharedMonos.probe,1);
			numShared.monos = sum(cellfun(@(x) length(x), ... 
				sharedMonos.probe(:, 2)));
			if numShared.monos == 0
				score = 99;
			else
				%numShared.dis = size(sharedDis.probe,1);
				means.monos = [sharedMonos.ref(:,[1 3]), sharedMonos.probe(:,3)];

				
				absDist = obj.getAbsoluteDistance(means, numShared);
				relDist = obj.getRelativeDistance(means, numShared);
				
				score = absDist + relDist;
			end
		end
		%}
		
		function dist = getRelativeDistance(obj, means, numShared, weights)
			monoDist = obj.getPartialRelDist(means.monos);
			if numShared.diPPsUnique == 0
				diPPDist = 99;
			else
				diPPDist = obj.getPartialRelDist(means.diPP);
			end
			
			if numShared.diRPsTotal == 0
				diRPDist = 99;
			else
				diRPDist = obj.getPartialRelDist(means.diRP);
			end
			
			mostShared = max([numShared.monosTotal, numShared.diPPsTotal, ... 
				numShared.diRPsTotal]);
			% If only one digraph is shared, relative distance does not apply
			dist = monoDist*(numShared.monosTotal/mostShared);
			if numShared.diPPsUnique > 1
				dist = dist + diPPDist*(weights.diPPs/mostShared);
			end
			if numShared.diRPsUnique > 1
				dist = dist + diRPDist*(weights.diRPs/mostShared);
			end
				%dist = monoDist*(numShared.monos/mostShared) + ...
				%	diPPDist*(numShared.dis/mostShared) + ...
				%	diRPDist*(numShared.dis/mostShared);
		end
		
		function relDist = getPartialRelDist(obj, means)
			refMeans = means(:,[1 2]);
			probeMeans = means(:,[1 3]);
			sortedRefMeans = sortrows(refMeans,2);
			sortedProbeMeans = sortrows(probeMeans,2);
			positions = NaN(size(sortedRefMeans,1),2);
			
			for ii = 1:size(sortedProbeMeans,1)
				index = find(strcmp(sortedRefMeans{ii,1},sortedProbeMeans(:,1)));
				positions(ii,:) = [ii, index];
			end
			
			differences = abs(diff(positions,[],2));
			diffLength = length(differences);
			maxDisorder = ((diffLength^2)-mod(diffLength,2))/2;
			relDist = sum(differences) / maxDisorder;
		end
		
		function dist = getAbsoluteDistance(obj, means, numShared, weights)
			monoDist = obj.getPartialAbsDist(means.monos, numShared.monosUnique);
			diPPDist = obj.getPartialAbsDist(means.diPP, numShared.diPPsUnique);
			diRPDist = obj.getPartialAbsDist(means.diRP, numShared.diRPsUnique);
			
			mostShared = max([numShared.monos, numShared.diRPs, numShared.diPPs]);
			
			dist = monoDist*(weights.monos/mostShared) + ...
				diPPDist*(weights.diPPs/mostShared) + ... 
				diRPDist*(weights.diRPs/mostShared);
		end
		
		function dist = getPartialAbsDist(obj, means, uniqueShared)
			if uniqueShared == 0
				dist = 99;
			else
				sortedMeans = sort(cell2mat(means(:,2:3)),2);
				comparisons = sortedMeans(:,2) ./ sortedMeans(:,1);
				
				similars = comparisons < 1.25;
				dist = 1 - sum(nonzeros(similars))/uniqueShared;
			end
		end
		
		function sharedMonos = getSharedMonos(obj, monographs)
			sharedLogical = ismember(obj.monoRef(:,1), monographs(:,1));
			sharedMonos.ref = obj.monoRef(sharedLogical,:);
			sharedLogical = ismember(monographs(:,1), obj.monoRef(:,1));
			sharedMonos.probe = monographs(sharedLogical,:);
		end
		
		function sharedDigraphs = getSharedDigraphs(obj, digraphs)
			%{
			refIndices = NaN(size(digraphs,1),1);
			probeIndices = false(size(digraphs,1),1);
			for kk = 1:length(refIndices)
				index = find(strcmp(obj.diRef(:,1), digraphs{kk,1}) & ...
						strcmp(obj.diRef(:,2), digraphs{kk,2}));
				if ~isempty(index)
					refIndices(kk) = index;
					probeIndices(kk) = true;
				end
			end
			
			sharedDigraphs.ref = obj.diRef(refIndices(~isnan(refIndices)),:);
			sharedDigraphs.probe = digraphs(probeIndices,:);
			%}
			%digraphs(:,1) = strcat(digraphs(:,1), digraphs(:,2));
			sharedLogical = ismember(obj.diRef(:,1), digraphs(:,1));
			sharedDigraphs.ref = obj.diRef(sharedLogical,:);
			sharedLogical = ismember(digraphs(:,1), obj.diRef(:,1));
			sharedDigraphs.probe = digraphs(sharedLogical,:);
		end
		
		%{
		function collection = getSharedDis(obj, digraphs)
			%{
			sharedLogical = ismember(digraphs(:,1:2), obj.diRef(:,1:2));
			ind = sharedLogical(:,1) & sharedLogical(:,2);
			sharedProbe = digraphs(ind,:);
			%}
			
			sharedLogical = ismember(obj.diRef(:,1:2), digraphs(:, 1:2));
			ind = sharedLogical(:,1) & sharedLogical(:,2);
			sharedRef = obj.diRef(ind,:);
			numShared = length(sharedRef);
			collection = cell(numShared*2, size(sharedRef,2));
			collectionRow = 1;
			refRowNum = 1;
			while collectionRow <= numShared*2
				index = find(strcmp(digraphs(:,1), sharedRef(refRowNum,1)) & ...
					strcmp(digraphs(:,2),sharedRef(refRowNum,2)));
				if ~isempty(index)
					collection(collectionRow,:) = sharedRef(collectionRow,:);
					collection(collectionRow+1,:) = digraphs(index,:);
					%{
					if length(refRow{3}) == 1
						score = -1;
					else
						latMeans = cell2mat(refRow(3:6));
						latStds = cell2mat(refRow(7:10));
						dists = NaN(1,4);
						for ii = 1:4
							diff = abs(probe{ii+2}-latMeans(ii));
							% Handle edge cases where the feature matches the exact
							% expected value. Also, handle cases where stdv is 0.
							if diff == 0
								diff = 0.0001;
							end
							if latStds(ii) == 0
								latStds(ii) = 0.1;
							end
							dists(ii) = diff/latStds(ii);
						end
						score = mean(dists);
					end
					%}
				end
			end
		end
		%}
		
		function score = getDiScore(obj, probe)
			index = find(strcmp(obj.reference(:,1), probe{1}) && ...
				strcmp(obj.reference(:,2), probe{3}));
			refRow = obj.reference(index, :);
			
			[minDist, meanDist] = obj.diSMD(probe, refRow);
			maxDist = obj.diCD(probe, refRow);
			score = (meanDist * maxDist) / minDist;
		end
		
		function [minDist, meanDist, maxDist] = monoSMD(obj, probe)
			%METHOD1 Calculates the Scaled Manhattan Distance between the probe 
			%monograph and reference.
			%	A distance is calculated for every occurrence of the monograph in 
			%	the reference. The function returns the min, mean and max distance.
			index = find(strcmp(obj.reference(:,1), probe{1}));
			durs = obj.reference{index, 2};
			stdv = obj.reference{index, 4};
			
			distances = abs(probe{2}-durs)./stdv;
			minDist = min(distances);
			meanDist = mean(distances);
			maxDist = max(distances);
		end
		
		function [minDist, meanDist] = diSMD(obj, probe, refRow)
			stdv = refRow{8};
			ppDistances = (abs(probe{3}-refRow{3}))./stdv(1);
			prDistances = (abs(probe{4}-refRow{4}))./stdv(2);
			rpDistances = (abs(probe{5}-refRow{5}))./stdv(3);
			rrDistances = (abs(probe{6}-refRow{6}))./stdv(4);
			
			totalDist = ppDistances+prDistances+rpDistances+rrDistances;
			minDist = min(totalDist);
			meanDist = mean(totalDist);
		end
		
		function set.monoRef(obj, monoRefIn)
			obj.monoRef = monoRefIn;
		end
		
		function set.diRef(obj, diRefIn)
			obj.diRef = diRefIn;
		end
	end
end

