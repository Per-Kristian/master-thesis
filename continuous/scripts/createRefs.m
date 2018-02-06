function createRefs(user, keystrokes)
% portion is how large of a portion is to be used as training data, in the
% range of 0 to 1.


monoFeatures = FeatureExtractor.extractSingleActions(keystrokes);
toFile = sprintf(strcat(monopath, 'User_%02d.mat'), user);
if ~isdir(monopath)
	mkdir(monopath);
end
save(toFile, 'monoFeatures');

diFeatures = FeatureExtractor.extractDigraphActions(keystrokes);
toFile = sprintf(strcat(dipath, 'User_%02d.mat'), user);
if ~isdir(dipath)
	mkdir(dipath);
end
save(toFile, 'diFeatures');
end