classdef FeatureExtractor
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess = private)
		singles
		digraphs
	end
	
	methods (Static)
		function singleActions = extractSingleActions(keystrokes)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			
			uniqueChars = unique(keystrokes(:,1));
			singleActions = cell(length(uniqueChars), 4);
			
			for ii=1:length(uniqueChars)
				singleActions{ii,1} = uniqueChars{ii};
				%todo: retreive indices from unique instead
				indices = find(strcmp(keystrokes(:,1), ...
					uniqueChars{ii}));
				singleActions{ii,2} = cell2mat(keystrokes(indices, 2));
				singleActions{ii,3} = nanmean(singleActions{ii,2});
				singleActions{ii,4} = nanstd(singleActions{ii,2});
			end
		end
		
		function digraphActions = extractDigraphActions(keystrokes)
			% Store strings in one cell string:
			Strings  = keystrokes(:, [1, 3]);
			[uStrings, iStrings, iUniq] = unique(string(Strings), 'rows');
			Values = cell2mat(keystrokes(:, [2, 4]));
			% todo Do we really need to check duration here? remDur.
			validValues = Values(:, 2) < 1500;
			%validValues = (Values(:, 1) < 100000);
			
			% Pre-allocate memory for cell array
			digraphActions = cell(length(uStrings),8);
			uStringsCell = cellstr(uStrings);
			digraphActions(:, 1:2) = uStringsCell(:, 1:2);

			for ii = 1:length(uStrings)
				% Find rows containing the current unique digraph
				occurIndices = find(iUniq == ii & validValues);
				[pp,pr,rp,rr] = ... 
					FeatureExtractor.getRefLats(occurIndices, keystrokes);
				%Return digraphs with latencies
				digraphActions{ii,3} = pp;
				digraphActions{ii,4} = pr;
				digraphActions{ii,5} = rp;
				digraphActions{ii,6} = rr;
				digraphActions{ii,7} = ...
					[nanmean(pp),nanmean(pr),nanmean(rp),nanmean(rr)];
				digraphActions{ii,8} = ... 
					[nanstd(pp),nanstd(pr),nanstd(rp),nanstd(rr)];
			end
			% remove rows without valid latencies
			meanCol = cell2mat(digraphActions(:,7));
			digraphActions = digraphActions(~any(isnan(meanCol),2),:);
			
			%indices = find(strcmp(keystrokes(:,1), ...
			%	uniqueDigraphs{}))
			
		end
		
		function probe = createDiProbe(digraphRow, nextRow)
			probe = cell(6);
			probe{1} = digraphRow{1};
			probe{2} = digraphRow{3};
			
			lats = calcLats(digraphRow, nextRow);
			probe{3} = lats(1);
			probe{4} = lats(2);
			probe{5} = lats(3);
			probe{6} = lats(4);
		end
		
		function [pps,prs,rps,rrs] = getRefLats(occurIndices, keystrokes)
			pps = zeros(1, length(occurIndices));
			prs = zeros(1, length(occurIndices));
			rps = zeros(1, length(occurIndices));
			rrs = zeros(1, length(occurIndices));
			
			for jj = 1:length(occurIndices)
				% todo: avoid using this if statement inside loop.
				if occurIndices(jj) ~= length(keystrokes)
					digraphRow = keystrokes(occurIndices(jj),:);
					nextRow = keystrokes(occurIndices(jj)+1,:);
					[pp,pr,rp,rr] = ... 
						FeatureExtractor.calcLats(digraphRow, nextRow);
					pps(jj) = pp;
					prs(jj) = pr;
					rps(jj) = rp;
					rrs(jj) = rr;
				end
			end
		end
		
		function [pp,pr,rp,rr] = calcLats(digraphRow, nextRow)
			% Check if the first key in the next row is the correct one. If 
			% not, the behavior logging tool may have been paused at that 
			% point, or some error may have occurred during keylogging.
			nextKeyIsCorrect = strcmp(digraphRow{3}, nextRow{1});
			if nextKeyIsCorrect
				pp = digraphRow{2} + digraphRow{4};
				pr = digraphRow{2} + digraphRow{4}+nextRow{2};
				rp = digraphRow{4};
				rr = digraphRow{4} + nextRow{2};
			else
				pp = NaN;
				pr = NaN;
				rp = NaN;
				rr = NaN;
			end
		end
	end
end

