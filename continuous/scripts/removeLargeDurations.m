function removeLargeDurations(user)
if strcmp('all', user)
	for ii = 1:57
		filename = sprintf('../../../Data/raw/User_%02d.mat', ii);
		rawData = importdata(filename);
		remDurs(ii, rawData);
	end
	disp('Created filtered files for all users');
else
	filename = sprintf('../../../Data/raw/User_%02d.mat', user);
	rawData = importdata(filename);
	remDurs(user, rawData);
	disp('Created filtered file for single user.');
end
end

function remDurs(user, rawData)
filename = sprintf('../../../Data/filtered/User_%02d.mat', user);
noLargeDurations = rawData(cat(2, rawData{:,2})<100000,:);
save(filename, 'noLargeDurations');
end