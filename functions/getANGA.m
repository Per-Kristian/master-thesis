function [anga, notLocked] = getANGA(row)
%GETANGA Return current user's ANGA. If they were never locked
%out, notLocked is true.
if row(1) == -1
	anga = row(2);
	notLocked = true;
else
	anga = row(1);
	notLocked = false;
end
end

