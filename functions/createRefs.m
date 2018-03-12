function createRefs(user, keystrokes, full)
% full should be FALSE if mean and stdv are the only needed values in 
% references.
monoRef = FeatureExtractor.extractSingleActions(keystrokes);
diRef = FeatureExtractor.extractDigraphActions(keystrokes, full);
FileIO.writeRefs(user, monoRef, diRef, full);
end