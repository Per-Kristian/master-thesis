function createRefs(user, keystrokes)
% portion is how large of a portion is to be used as training data, in the
% range of 0 to 1.
monopath = '../../../Data/filtered/MonographFeatures/';
dipath = '../../../Data/filtered/DigraphFeatures/';

monoFeatures = FeatureExtractor.extractSingleActions(keystrokes);
toFile = sprintf(strcat(monopath, 'User_%02d.mat'), user);
save(toFile, 'monoFeatures');

diFeatures = FeatureExtractor.extractDigraphActions(keystrokes);
toFile = sprintf(strcat(dipath, 'User_%02d.mat'), user);
save(toFile, 'diFeatures');
end