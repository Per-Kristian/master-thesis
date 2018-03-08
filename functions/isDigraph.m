function isDigraph = isDigraph(prevRow, currRow)
%ISDIGRAPH Returns true if the two rows are considered a digraph.
isDigraph = strcmp(prevRow{3}, currRow{1}) && ...
						prevRow{4} < FeatureExtractor.maxFlightTime;
end

