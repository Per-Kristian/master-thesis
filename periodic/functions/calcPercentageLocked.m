function percentage = calcPercentageLocked(resultArr)
percentage = NaN;
if ~isempty(resultArr)
	numLocked = sum(resultArr(:,1));
	numEngaged = sum(resultArr(:,2));
	if numEngaged > 0
		percentage = numLocked/numEngaged*100;
	end
end
end

