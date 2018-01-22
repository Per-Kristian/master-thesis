function runSimpleSMD(user)
%Expects either an integer or 'all'. Runs the authentication system with
%either a specific user or all users, specifically using simple Scaled 
%Manhattan Distance based on mean and standard deviation.
filteredPath = '../../../Data/filtered/';
monoPath = '../../../Data/filtered/MonographFeatures/';
diPath = '../../../Data/filtered/DigraphFeatures/';

if strcmp('all', user)
	matcher = Matcher;
	for ii = 1:57
		fromFile = sprintf(strcat(monoPath, 'User_%02d.mat'), ii);
		monoRef = importdata(fromFile);
		fromFile = sprintf(strcat(diPath, 'User_%02d.mat'), ii);
		diRef = importdata(fromFile);
		fromFile = sprintf(strcat(filteredPath, 'User_%02d.mat'), ii);
		fullFile = importdata(fromFile);
		
		matcher.monoRef = monoRef;
		matcher.diRef = diRef;
		fullLength = length(fullFile);
		for jj = 1:fullLength
			probe = fullFile(jj, 1:2);
			score = matcher.getSimpleMonoScore(probe);
			% todo: send to trust model
		end
		
	end
else
	
end
end