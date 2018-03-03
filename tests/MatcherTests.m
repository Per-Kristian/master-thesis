classdef MatcherTests < matlab.unittest.TestCase
	%MATCHERTESTS Summary of this class goes here
	%   Detailed explanation goes here
	
	methods (Test)
		function testAbsoluteDistance()
			%MATCHERTESTS Construct an instance of this class
			%   Detailed explanation goes here
			matcher = Matcher(monoRefs.User_01, diRefs.User02);
			testSet = testSets.User_04(1:2, :);
			
			matcher.dwellDistance(testSet);
			
			
		end
		
		function outputArg = method1(obj,inputArg)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			outputArg = obj.Property1 + inputArg;
		end
	end
end

