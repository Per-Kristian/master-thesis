classdef FileIO
	%FILEIO This class contains static methods for I/O.
	properties (Constant, GetAccess = public)
		PROOT = fullfile(userpath, '/matlab_projects/');
		PDATA = fullfile(userpath, '/matlab_projects/Data/');
		PFILTERED = fullfile(userpath,'/matlab_projects/Data/filtered/');
		PRAW = fullfile(userpath, 'matlab_projects/Data/raw/');
		PRESULTS = fullfile(userpath,'/matlab_projects/Data/results/');
		PMONO = fullfile(userpath,'/matlab_projects/Data/filtered/MonographFeatures/');
		PDI = fullfile(userpath,'/matlab_projects/Data/filtered/DigraphFeatures/');
		PTEST = fullfile(userpath,'/matlab_projects/Data/filtered/testing/');
		PVALID = fullfile(userpath,'/matlab_projects/Data/filtered/validation/');
	end
	
	methods (Static)
		function testSet = readTestSet(imposter)
			fromFile = ...
				fullfile(FileIO.PTEST,sprintf('User_%02d.mat',imposter));
			testSet = importdata(fromFile);
		end
		
		function writeTestSet(user, keystrokes) %#ok<INUSD>
			toFile = fullfile(FileIO.PTEST,sprintf('User_%02d.mat',user));
			if ~isdir(FileIO.PTEST)
				mkdir(FileIO.PTEST);
			end
			save(toFile, 'keystrokes');
		end
		
		function writeValidationSet(user, keystrokes) %#ok<INUSD>
			toFile = fullfile(FileIO.PVALID,sprintf('User_%02d.mat',user));
			if ~isdir(FileIO.PVALID)
				mkdir(FileIO.PVALID);
			end
			save(toFile, 'keystrokes');
		end
		
		function writeRefs(user, monoRef, diRef) %#ok<INUSD>
			toFile = fullfile(FileIO.PMONO,sprintf('User_%02d.mat',user));
			if ~isdir(FileIO.PMONO)
				mkdir(FileIO.PMONO);
			end
			save(toFile, 'monoRef');
			toFile = fullfile(FileIO.PDI,sprintf('User_%02d.mat',user));
			if ~isdir(FileIO.PDI)
				mkdir(FileIO.PDI);
			end
			save(toFile, 'diRef');
		end
		
		function [monoRef, diRef] = readRefs(user)
			%	Returns both Monograph and Digraph references.
			%	[m, d] = fetchRef(3) returns mono- and digraph references
			%	for user 3.
			fromFile = fullfile(FileIO.PMONO,sprintf('User_%02d.mat',user));
			if exist(fromFile, 'file') == 2
				monoRef = importdata(fromFile);
			end
			fromFile = fullfile(FileIO.PDI,sprintf('User_%02d.mat', user));
			if exist(fromFile, 'file') == 2
				diRef = importdata(fromFile);
			end
		end
		
		function filtered = readFiltered(user)
			fromFile = fullfile(FileIO.PFILTERED, ...
				sprintf('User_%02d.mat', user));
			filtered = importdata(fromFile);
		end
		
		function writeSingleResult(user, imposter, ... 
				type, paramID, numUsers, trustProgress, avgActions) %#ok<INUSD>
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			resPath = fullfile(FileIO.PRESULTS,type,sprintf('/%d_%d/', ... 
				paramID, numUsers));
			userResFolder = fullfile(resPath, ... 
				sprintf('User_%02d.mat',user));
			impFolder = fullfile(userResFolder, ... 
				sprintf('User_%02d.mat',imposter));
			if ~isdir(impFolder)
				mkdir(impFolder);
			end
			toFile = strcat(impFolder, 'result.mat');
			save(toFile, 'avgActions');
		end
		
		function rawData = readRawData(user)
			filename = fullfile(FileIO.PRAW, sprintf('User_%02d.mat', user));
			rawData = importdata(filename);
		end
		
		function writeFilteredData(user, data) %#ok<INUSD>
			if ~isdir(FileIO.PFILTERED)
				mkdir(FileIO.PFILTERED);
			end
			filename = ... 
				fullfile(FileIO.PFILTERED,sprintf('/User_%02d.mat', user));
			save(filename, 'data');
		end
		
		function pwd = getPassword()
			%GETPASSWORD returns the database password.
			%	Pwd is simply read from a file outside of the repo's scope, 
			%	preventing sneaky GitHub lurkers from gettin' jiggy wit it.
			pwd = importdata(fullfile(FileIO.PROOT,'db/password.mat'));
		end
	end
end

