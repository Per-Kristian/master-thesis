rawData = importdata("../../../Data/User_08.mat");
noLargeDurations = rawData(cat(2, rawData{:,2})<100000,:);
save('../../../Data/filtered/User_08.mat', 'noLargeDurations');