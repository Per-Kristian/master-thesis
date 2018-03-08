classdef MatcherTests < matlab.unittest.TestCase
	%MATCHERTESTS Summary of this class goes here
	%   Detailed explanation goes here
	
	methods (Test)
		function testAbsoluteMonoDistance()
			%MATCHERTESTS Construct an instance of this class
			%   Detailed explanation goes here
			monoRef = {
				'h',90,90,0;
				'e',[57;110;60],75.6667,29.7714;
				'l',[60;76;76;76],72,8;
				'o',[70;70;70;63],68.2500,3.5000;
				'x',[20;25], 22.5, 3.5355;
				};
			
			diRef = {
				{'h'}, {'e'}, 0, 0, 0, 0, {[145.8000,252.4000,70.4333,182.0333]}
				{'e'}, {'l'}, 0, 0, 0, 0, {[100,258.4000,77.4333,186.0333]}
				{'l'}, {'l'}, 0, 0, 0, 0, {[149.8000,258.4000,77.4333,186.0333]}
				{'l'}, {'o'}, 0, 0, 0, 0, {[149.8000,258.4000,77.4333,186.0333]}
				{'h'}, {'x'}, 0, 0, 0, 0, {[149.8000,258.4000,77.4333,186.0333]}
			};
				
			
			matcher = Matcher(monoRef, diRefs.User01);
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

