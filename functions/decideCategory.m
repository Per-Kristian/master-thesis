function category = decideCategory(p1, p2)
%DECIDECATEGORY Returns which category the result belongs in.
%	Categories:
%	(+/+) = 1, (+/-) = 2, (-/+) = 3, (-/-) = 4.
if p1 && p2
	category = 1;
elseif p1 && ~p2
	category = 2;
elseif ~p1 && p2
	category = 3;
else
	category = 4;
end
end

