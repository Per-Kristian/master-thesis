classdef FileIO
	%FILEIO This class contains static methods for I/O.
	properties (Constant, GetAccess = public)
		PROOT = fullfile(userpath, '/matlab_projects/');
		PDB = fullfile(userpath, '/matlab_projects/db/');
		PDATA = fullfile(userpath, '/matlab_projects/Data/');
		PFILTERED = fullfile(userpath,'/matlab_projects/Data/filtered/');
		PPERSPARAMS = fullfile(userpath,'/matlab_projects/Data/persParams/');
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
		
		function validSet = readValidationSet(user)
			fromFile = fullfile(FileIO.PVALID,sprintf('User_%02d.mat',user));
			if exist(fromFile, 'file') == 2
				validSet = importdata(fromFile);
			end
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
		
		function writeSingleResult(userName, imposterName, ... 
				type, paramID, numUsers, trustProgress, avgActions, fast)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			if fast
				process = 'fast';
			else
				process = 'full';
			end
			resPath = fullfile(FileIO.PRESULTS,type,sprintf('/%d_%d_%s/', ...
				paramID, numUsers, process));
			userResFolder = fullfile(resPath, sprintf('%s/',userName));
			impFolder = fullfile(userResFolder, sprintf('%s/',imposterName));
			if ~isdir(impFolder)
				mkdir(impFolder);
			end
			result.avgActions = avgActions;
			result.trustProgress = trustProgress; %#ok<STRNU>
			toFile = strcat(impFolder, 'result.mat');
			save(toFile, 'result');
		end
		
		function result = readSingleResult(userName, imposterName, type, ...
				paramID, numUsers,fast)
			if fast
				process = 'fast';
			else
				process = 'full';
			end
			resPath = fullfile(FileIO.PRESULTS,type,sprintf('/%d_%d_%s/', ...
				paramID, numUsers, process));
			userResFolder = fullfile(resPath, sprintf('%s/',userName));
			impFolder = fullfile(userResFolder, sprintf('%s/',imposterName));
			fromFile = fullfile(impFolder, 'result.mat');
			if exist(fromFile, 'file') == 2
				result = importdata(fromFile);
			end
		end
		
		function writeScores(userName, imposterName, type, setType, scores) %#ok<INUSD>
			dirPath = fullfile(FileIO.PRESULTS, type, '/scores/', setType, ...
				'/', userName);
			if ~isdir(dirPath)
				mkdir(dirPath);
			end
			toFile = fullfile(dirPath, sprintf('/%s.mat', imposterName));
			save(toFile, 'scores');
		end
		
		function scores = readScores(userName, imposterName, type, setType)
			dirPath = fullfile(FileIO.PRESULTS, type, '/scores/', setType, ...
				'/', userName);
			fromFile = fullfile(dirPath,sprintf('/%s.mat',imposterName));
			if exist(fromFile, 'file') == 2
				scores = importdata(fromFile);
			else
				fprintf('Error, file not found: %s', fromFile);
				scores = NaN;
			end
		end
		
		function num = countScoreUserDirs(classifier, setType)
			%COUNTSCOREUSERDIRS Counts the amount of users who have precalculated
			%scores for a specified classifier and set type (test or validation).
			S = dir(fullfile(FileIO.PRESULTS, classifier, '/scores/', setType));
			num = sum([S(~ismember({S.name},{'.','..'})).isdir]);
		end
		
		function writePersonalParams(userName, classifier, params) %#ok<INUSD>
			dirPath = fullfile(FileIO.PPERSPARAMS, classifier);
			if ~isdir(dirPath)
				mkdir(dirPath);
			end
			toFile = fullfile(dirPath, sprintf('/%s.mat', userName));
			save(toFile, 'params');
		end
		
		function params = readPersonalParams(userName, classifier)
			dirPath = fullfile(FileIO.PPERSPARAMS, classifier);
			fromFile = fullfile(dirPath,sprintf('/%s.mat',userName));
			if exist(fromFile, 'file') == 2
				params = importdata(fromFile);
			else
				fprintf('Error, file not found: %s', fromFile);
				params = NaN;
			end
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
		
		function conf = getDbConf(systemType)
			%GETDBCONF returns the database configuration.
			%	Conf is simply read from a file outside of the repo's scope,
			%	preventing sneaky GitHub lurkers from gettin' jiggy wit it.
			conf = importdata(fullfile(FileIO.PDB, systemType, '/dbconf.mat'));
		end
	end
end

