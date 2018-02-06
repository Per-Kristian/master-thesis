classdef FileIO
	%FILEIO This class contains static methods for I/O.
	
	methods (Static)
		function testSet = readTestSet(imposter)
			testPath = 'Data/filtered/testing/';
			fromFile = sprintf(strcat(testPath,'User_%02d.mat'), imposter);
			testSet = importdata(fromFile);
		end
		
		function writeRefs(user, monoRef, diRef)
			monopath = '../../../Data/filtered/MonographFeatures/';
			dipath = '../../../Data/filtered/DigraphFeatures/';
			
			toFile = sprintf(strcat(monopath, 'User_%02d.mat'), user);
		end
		
		function [monoRef, diRef] = readRefs(user)
			%	Returns both Monograph and Digraph references.
			%	[m, d] = fetchRef(3) returns mono- and digraph references
			%	for user 3.
			monoPath = 'Data/filtered/MonographFeatures/';
			diPath = 'Data/filtered/DigraphFeatures/';
			
			fromFile = sprintf(strcat(monoPath, 'User_%02d.mat'), user);
			if exist(fromFile, 'file') == 2
				monoRef = importdata(fromFile);
			end
			fromFile = sprintf(strcat(diPath, 'User_%02d.mat'), user);
			if exist(fromFile, 'file') == 2
				diRef = importdata(fromFile);
			end
		end
		
		function writeSingleResult(user, imposter, ... 
				type, paramID, trustProgress)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			resPath = strcat('Data/results/',type,sprinft('/%d/',paramID));
			userResFolder = sprintf(strcat(resPath, 'User_%02d/'), user);
			impFolder = sprintf(strcat(userResFolder, ... 
				'User_%02d/'), imposter);
			if ~isdir(impFolder)
				mkdir(impFolder);
			end
			toFile = strcat(impFolder, 'trustProgress.mat');
			save(toFile, 'trustProgress');
		end
		
		function rawData = readRawData(user)
			filename = sprintf('Data/raw/User_%02d.mat', user);
			rawData = importdata(filename);
		end
		
		function saveFilteredData(user, data)
			filename = ... 
				sprintf('/Data/filtered/User_%02d.mat', user);
			save(filename, 'data');
		end
		
		function pwd = getPassword()
			pwd = importdata('db/password.mat');
		end
	end
end

