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
		
		function [min, mean, max] = monoSMD(obj, probe)
			%METHOD1 Calculates the Scaled Manhattan Distance between the
			%probe monograph and reference.
			%	A distance is calculated for every occurrence of the
			%	monograph in the reference. The function returns the
			%	minimum, mean and maximum distance.
			index = find(strcmp(obj.reference(:,1), probe{1}));
			durs = obj.reference{index, 2};
			stdv = obj.reference{index, 4};
			
			distance = abs(probe{2}-durs)./stdv;
		end
	end
end

