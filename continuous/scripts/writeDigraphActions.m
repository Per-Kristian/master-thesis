function writeDigraphActions(user)
tic
dipath = '../../../Data/filtered/DigraphFeatures/';
if strcmp('all', user)
	for ii = 1:57
		% Extract monograph features for all users
		fromFile = sprintf('../../../Data/filtered/User_%02d.mat', ii);
		keystrokes = importdata(fromFile);
		features = FeatureExtractor.extractDigraphActions(keystrokes);
		toFile = sprintf(strcat(dipath, 'User_%02d.mat'), ii);
		save(toFile, 'features');
	end
	disp(strcat('Wrote digraph features for all users to ', dipath));
else
	% Extract monograph features for a specific user
	fromFile = sprintf('../../../Data/filtered/User_%02d.mat', user);
	keystrokes = importdata(fromFile);
	features = FeatureExtractor.extractDigraphActions(keystrokes);
	toFile = sprintf(strcat(dipath, 'User_%02d.mat'), user);
	save(toFile, 'features');
	disp(strcat('Wrote digraph features to ', toFile));
end
toc
end