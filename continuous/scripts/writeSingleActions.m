function writeSingleActions(user)
tic
monopath = '../../../Data/filtered/MonographFeatures/';
if strcmp('all', user)
	for ii = 1:57
		% Extract monograph features for all users
		fromFile = sprintf('../../../Data/filtered/User_%02d.mat', ii);
		keystrokes = importdata(fromFile);
		features = FeatureExtractor.extractSingleActions(keystrokes);
		toFile = sprintf(strcat(monopath, 'User_%02d.mat'), ii);
		save(toFile, 'features');
	end
	disp(strcat('Wrote monograph features for all users to ', monopath));
else
	% Extract monograph features for a specific user
	filename = sprintf('../../../Data/filtered/User_%02d.mat', user);
	keystrokes = importdata(filename);
	features = FeatureExtractor.extractSingleActions(keystrokes);
	toFile = sprintf(strcat(monopath, 'User_%02d.mat'), user);
	save(toFile, 'features');
	disp(strcat('Wrote monograph features to ', toFile));
end
toc
end