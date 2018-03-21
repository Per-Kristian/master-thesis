function percentage = calcPercentageLocked(resultArr)
if ~isempty(resultArr)
	percentage = sum(resultArr(:,1))/sum(resultArr(:,2))*100;
else
	percentage = NaN;
end
end

