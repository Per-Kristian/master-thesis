classdef TrustModel < handle
	%TRUSTMODEL Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		trust % current trust level
		A
		B
		C
		D
	end
	
	methods
		function obj = TrustModel(threshold, width, maxRwrd, maxPen)
			%TRUSTMODEL Construct an instance of this class
			%	Params: 
			%	threshold = reward/penalty threshold, B = width,
			%	C = max reward, D = max penalty
			obj.trust = 100;
			obj.A = threshold;
			obj.B = width;
			obj.C = maxRwrd;
			obj.D = maxPen;
		end
		
		function newTrust = alterTrust(obj, score)
			%ALTERTRUST Alters the current trust level.
			%   Takes a dissimilarity score (number of standard
			%   deviations) as input. Calculates a change of trust and sets
			%   the new trust level accordingly. Returns new trust level.
			
			numerator = obj.D .* (1+1 ./ obj.C);
			denominator = (1 ./ obj.C)+exp((score-obj.A) ./ obj.B);
			frac = numerator./denominator;
			
			delta = min(-obj.D + frac, obj.C);
			obj.trust = min(max(obj.trust + delta, 0), 100);
			newTrust = obj.trust;
		end
	end
end

