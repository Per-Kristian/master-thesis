function createRefs(user, keystrokes)
% portion is how large of a portion is to be used as training data, in the
% range of 0 to 1.
monoRef = FeatureExtractor.extractSingleActions(keystrokes);
diRef = FeatureExtractor.extractDigraphActions(keystrokes);
FileIO.writeRefs(user, monoRef, diRef);
end