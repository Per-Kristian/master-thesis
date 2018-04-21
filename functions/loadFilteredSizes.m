function filteredSizes = loadFilteredSizes()
%LOADFILTEREDSIZES Summary of this function goes here
%   Detailed explanation goes here
numFiles = length(dir(strcat(userpath,'/matlab_projects/Data/filtered/','*.mat')));
filteredSizes = NaN(numFiles,1);

for ii = 1:numFiles
	fprintf("Reading User %d's size..\n",ii);
	matObj = matfile(fullfile(FileIO.PFILTERED, sprintf('User_%02d.mat', ii)));
	info = whos(matObj, 'data');
	filteredSizes(ii) = info.size(1);
end
end

