classdef FileIO
	%FILEIO This class contains static methods for I/O.
	
	methods (Static)
		%{
		function obj = FileIO(inputArg1,inputArg2)
			%FILEIO Construct an instance of this class
			%   Detailed explanation goes here
			obj.Property1 = inputArg1 + inputArg2;
		end
		%}
		
		function outputArg = writeResult(user, imposter, type, trustProgress)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			resPath = strcat('Data/results/', type, '/');
			userResFolder = sprintf(strcat(resPath, 'User_%02d/'), user);
			impFolder = sprintf(strcat(userResFolder, 'User_%02d/'), imposter);
			if ~isdir(impFolder)
				mkdir(impFolder);
			end
			toFile = strcat(impFolder, 'trustProgress.mat');
			save(toFile, 'trustProgress');
		end
	end
end

