classdef TrustModel < handle
	%TRUSTMODEL Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		trust % current trust level
		userParams
		A
		B
		C
		D
		missingScore
		singleOccScore
		range
	end
	
	methods
		function obj = TrustModel(userParams)
			%TRUSTMODEL Construct an instance of this class
			%	Params: 
			%	threshold = reward/penalty threshold, B = width,
			%	C = max reward, D = max penalty, missingScore = fixed 
			%	dissimilarity score for probe not present in reference, 
			%	singleOccScore = fixed dissimilarity score for only one 
			%	occurrence of probe in reference.
			obj.trust = 100;
			obj.userParams = userParams;
			if isfield(userParams, 'CA')
				CAParams = userParams.CA;
			else
				CAParams = userParams;
			end
			
			obj.A = CAParams.rwrdThreshold;
			obj.B = CAParams.width;
			obj.C = CAParams.maxRwrd;
			obj.D = CAParams.maxPen;
			obj.singleOccScore = CAParams.singleOccScore;
			obj.missingScore = CAParams.missingScore;
			obj.range = 100-CAParams.lockout;
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
			%{
			numerator = obj.D .* (1 + 1 ./ obj.C);
			denominator = (1 ./ obj.C)+exp((score-obj.A) ./ obj.B);
			frac = numerator./denominator;
			delta = min(-obj.D + frac, obj.C);
			%}
			% delta = obj.scoreFromSigmoid(obj.A, obj.B, obj.C, obj.D, score);
			delta = obj.deltaFromSigmoid(obj.A, obj.B, obj.D, score);
			obj.trust = min(max(obj.trust + delta, 0), 100);
			newTrust = obj.trust;
		end
		
		function newTrust = influence(obj, score)
			% Takes a score from a periodic authentication, and uses it to
			% influence the current trust level.
			inflParams = obj.userParams.infl;
			PAParams = obj.userParams.PA;
			if inflParams.type == 1
				%distToThresh = score-thresh;
				if score > obj.userParams.PA.lockout
					delta = -inflParams.downMult * obj.range;
				else
					delta = inflParams.upMult * obj.range;
				end
				obj.trust = min(max(obj.trust + delta, 0), 100);
				newTrust = obj.trust;
			elseif type == 2
				if isnan(inflParams.rwrdThreshold)
					rwrdThresh = PAParams.meanScore + inflParams.tolerance;
				end
				delta = obj.deltaFromSigmoid();
			end
		end
		
		function delta = deltaFromSigmoid(obj, rwrdThresh, width, ...
				maxPen, score) %#ok<INUSL>
			numerator = maxPen .* 2;
			denominator = 1 + exp((score-rwrdThresh) ./ width);
			frac = numerator./denominator;
			delta = -maxPen + frac;
		end
		
		%{
		OLD FUNCTION WITH MAXRWRD
		function delta = scoreFromSigmoid(obj, rwrdThresh, width, maxRwrd, ...
				maxPen, score) %#ok<INUSL>
			numerator = maxPen .* (1 + 1 ./ maxRwrd);
			denominator = (1 ./ maxRwrd) + exp((score-rwrdThresh) ./ width);
			frac = numerator./denominator;
			delta = min(-maxPen + frac, maxRwrd);
		end
		%}
		
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

