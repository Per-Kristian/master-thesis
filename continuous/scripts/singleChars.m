%param = importdata("../../Data/User_01.mat");
%singles = FeatureExtractor.extractSingleActions(param);
digraphs = FeatureExtractor.extractDigraphActions(param);