disp('Processing..');
numFiles = length(dir(fullfile('Data/raw/','*.mat')));
removedUsers = 0;
for ii = 1:numFiles
	rawData = FileIO.readRawData(ii);
	if length(rawData) >= 10000
		% Remove large durations and save the filtered data.
		filtered = rawData(cat(2, rawData{:,2})<100000,:);
		% Save file without creating holes in usernumbers.
		FileIO.saveFilteredData(ii-removedUsers, filtered);
	else
		% Don't save the data, and consider the user as removed.
		removedUsers = removedUsers + 1;
	end
end
fprintf('Created filtered files for %d users.', numFiles-removedUsers);