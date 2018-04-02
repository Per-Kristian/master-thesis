function createRefs(user, keystrokes)
% full should be FALSE if mean and stdv are the only needed values in 
% references.
monoRef = FeatureExtractor.extractSingleActions(keystrokes);
diRef = FeatureExtractor.extractDigraphActions(keystrokes);
FileIO.writeRefs(user, monoRef, diRef);
end