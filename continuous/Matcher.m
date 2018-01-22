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
			%   Expects a reference formatted by FeatureExtractor.
			if nargin>0
				obj.monoRef = varargin{1};
				obj.diRef = varargin{2};
			end
		end
		
		function score = getMonoScores(obj, probe)
			[minDist, meanDist, maxDist] = monoSMD(obj, probe);
			score = 1-(meanDist-minDist)/(maxDist-minDist);
		end
		
		function score = getSimpleMonoScore(obj, probe)
			index = find(strcmp(obj.monoRef(:,1), probe{1}));
			refRow = obj.monoRef(index, :);
			refMean = refRow{3};
			refStd = refRow{4};
			
			score = abs(probe{2}-refMean)/refStd;
		end
		
		function score = getSimpleDiScore(obj, probe)
			index = find(strcmp(obj.diRef(:,1), probe{1}) && ...
				strcmp(obj.diRef(:,2), probe{3}));
			refRow = obj.diRef(index, :);
			latMeans = refRow{7};
			latStds = refRow{8};
			ppDist = (abs(probe{3}-latMeans(1)))/latStds(1);
			prDist = (abs(probe{4}-latMeans(2)))/latStds(2);
			rpDist = (abs(probe{5}-latMeans(3)))/latStds(3);
			rrDist = (abs(probe{6}-latMeans(4)))/latStds(4);
			
			score = (ppDist + prDist + rpDist + rrDist) / 4;
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
			%METHOD1 Calculates the Scaled Manhattan Distance between the
			%probe monograph and reference.
			%	A distance is calculated for every occurrence of the
			%	monograph in the reference. The function returns the
			%	minimum, mean and maximum distance.
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
		
		function maxDist = diCD(obj, probe, refRow)
			% Returns the maximum Correlation Distance between the probe
			% and reference.
			
			
		end
		
		function set.monoRef(obj, monoRefIn)
			obj.monoRef = monoRefIn;
		end
		
		function set.diRef(obj, diRefIn)
			obj.diRef = diRefIn;
		end
	end
end

