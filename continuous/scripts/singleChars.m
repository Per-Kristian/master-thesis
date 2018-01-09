%param = importdata("../../../Data/filtered/User_08.mat");
%singles = FeatureExtractor.extractSingleActions(param);
digraphs = FeatureExtractor.extractDigraphActions(param);