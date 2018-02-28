classdef Matcher < handle
	%MATCHER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		monoRef
		diRef
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
			if nargin>0
				obj.monoRef = varargin{1};
				obj.diRef = varargin{2};
			end
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
					latMeans = refRow{7};
					latStds = refRow{8};
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

