testUnique = unique(param(:,1));
testValueSets = cell(length(testUnique), 2);

for i=1:length(testUnique)
	testValueSets{i,1} = testUnique(i);
	testIndices = find(strcmp(param(:,1), testUnique{i}));
	%testIndices = param(strcmp(param(:,1), testUnique{i}));
	%testIndices = param(:, strcmp(param(:,1), testUnique{i}));
	testValueSets{i,2} = cell2mat(param(testIndices, 2));

end