numUsers = numel(fieldnames(validSets));

for ii = 1:numUsers
	userName = getUserName(ii);
	
	theSet = validSets.(userName);
	durs = cell2mat(theSet(:,2));
	bin = durs == 0;
	indexes = find(bin);
	if length(indexes) > 0
		UsersWithIll.(userName) = indexes;
		disp(userName);
	end
end