classdef Matcher
	%MATCHER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (Access = private)
		reference
	end
	
	methods
		function obj = Matcher(reference)
			%MATCHER Construct an instance of this class
			%   Expects a reference formatted by FeatureExtractor.
			obj.reference = reference;
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
		
		function [minDist, meanDist] = diSMD(obj, probe)
			index = find(strcmp(obj.reference(:,1), probe{1}) && ...
				strcmp(obj.reference(:,2), probe{3}));
			refRow = obj.reference(index, :);
			stdv = refRow{8};
			
			ppDistances = (abs(probe{3}-refRow{3}))./stdv(1);
			prDistances = (abs(probe{4}-refRow{4}))./stdv(2);
			rpDistances = (abs(probe{5}-refRow{5}))./stdv(3);
			rrDistances = (abs(probe{6}-refRow{6}))./stdv(4);
			
			totalDist = ppDistances+prDistances+rpDistances+rrDistances;
			minDist = min(totalDist);
			meanDist = mean(totalDist);
		end
	end
end

