classdef TrustModel < handle
	%TRUSTMODEL Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		trust % current trust level
		A
		B
		C
		D
		missingScore
		singleOccScore
		range
	end
	
	methods
		function obj = TrustModel(params)
			%TRUSTMODEL Construct an instance of this class
			%	Params: 
			%	threshold = reward/penalty threshold, B = width,
			%	C = max reward, D = max penalty, missingScore = fixed 
			%	dissimilarity score for probe not present in reference, 
			%	singleOccScore = fixed dissimilarity score for only one 
			%	occurrence of probe in reference.
			
			obj.trust = 100;
			obj.A = params.rwrdThreshold;
			obj.B = params.width;
			obj.C = params.maxRwrd;
			obj.D = params.maxPen;
			obj.singleOccScore = params.singleOccScore;
			obj.missingScore = params.missingScore;
			obj.range = 100-params.lockout;
		end
		
		function newTrust = alterTrust(obj, score)
			%ALTERTRUST Alters the current trust level.
			% Takes a dissimilarity score (number of standard deviations) as 
			%	input. Calculates a change of trust and sets the new trust level 
			%	accordingly. Returns new trust level. If the score parameter is -1
			%	or -2, change it to a fixed score for edge cases.
			if score == -1
				score = obj.singleOccScore;
			elseif score == -2
				score = obj.missingScore;
			end
			numerator = obj.D .* (1 + 1 ./ obj.C);
			denominator = (1 ./ obj.C)+exp((score-obj.A) ./ obj.B);
			frac = numerator./denominator;
			delta = min(-obj.D + frac, obj.C);
			obj.trust = min(max(obj.trust + delta, 0), 100);
			newTrust = obj.trust;
		end
		
		function newTrust = influence(obj, score, inflParams, PALockout)
			% Takes a score from a periodic authentication, and uses it to
			% influence the current trust level.
			if strcmp(inflParams.type, 'decisionLevel')
				%distToThresh = score-thresh;
				if score > PALockout
					delta = -inflParams.downMult * obj.range;
				else
					delta = inflParams.upMult * obj.range;
				end
				obj.trust = min(max(obj.trust + delta, 0), 100);
				newTrust = obj.trust;
			end
		end
		
		function resetTrust(obj)
			obj.trust = 100;
		end
		
		%{
		function set.trust(obj,value)
			obj.trust = value;
		end
		%}
	end
end

