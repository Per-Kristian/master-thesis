classdef FeatureExtractor
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess = private)
		singles
		digraphs
	end
	
	properties (Constant)
		maxFlightTime = 1500
	end
	
	methods (Static)
		function singleActions = extractSingleActions(keystrokes)
			% METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			
			uniqueChars = unique(keystrokes(:,1));
			singleActions = cell(length(uniqueChars), 4);
			
			for ii=1:length(uniqueChars)
				singleActions{ii,1} = uniqueChars{ii};
				%todo: retreive indices from unique instead
				indices = find(strcmp(keystrokes(:,1), uniqueChars{ii}));
				allDurs = cell2mat(keystrokes(indices, 2));
				withoutOutliers = FeatureExtractor.removeOutliers(allDurs);
				singleActions{ii,2} = withoutOutliers;
				%singleActions{ii,2} = cell2mat(keystrokes(indices, 2)); this keeps
				%outliers.
				singleActions{ii,3} = nanmean(singleActions{ii,2});
				singleActions{ii,4} = nanstd(singleActions{ii,2});
			end
		end
		
		function digraphActions = ...
				extractDigraphActions(keystrokes, full)
			% Store strings in one cell string:
			Strings  = keystrokes(:, [1, 3]);
			[uStrings, ~, iUniq] = unique(string(Strings), 'rows');
			Values = cell2mat(keystrokes(:, [2, 4]));
			% todo Do we really need to check duration here? remDur.
			validValues = Values(:, 2) < FeatureExtractor.maxFlightTime;
			%validValues = (Values(:, 1) < 100000);
			% Pre-allocate memory for cell array
			if full
				digraphActions = cell(length(uStrings),14);
			else
				digraphActions = cell(length(uStrings),10);
			end
			uStringsCell = cellstr(uStrings);
			% todo: remove column two, and correct the usage in matcher etc
			digraphActions(:, 1) = strcat(uStringsCell(:, 1), uStringsCell(:,2));
			digraphActions(:, 2) = uStringsCell(:, 2);

			for ii = 1:length(uStrings)
				% Find rows containing the current unique digraph
				occurIndices = find(iUniq == ii & validValues);
				[ppO,prO,rpO,rrO] = ... These include outliers.
					FeatureExtractor.getDigraphLats(occurIndices, keystrokes);
				if length(ppO) > 1
					pp = FeatureExtractor.removeOutliers(ppO);
					pr = FeatureExtractor.removeOutliers(prO);
					rp = FeatureExtractor.removeOutliers(rpO);
					rr = FeatureExtractor.removeOutliers(rrO);
				else
					pp = ppO;
					pr = prO;
					rp = rpO;
					rr = rrO;
				end
				%Return digraphs with latencies
				digraphActions(ii,3:6) = ...
					{nanmean(pp),nanmean(pr),nanmean(rp),nanmean(rr)};
				digraphActions(ii,7:10) = ...
					{nanstd(pp),nanstd(pr),nanstd(rp),nanstd(rr)};
				if full
					digraphActions(ii,11:14) = {pp,pr,rp,rr};
				end
			end
			% remove rows without valid latencies
			meanCol = cell2mat(digraphActions(:,3));
			digraphActions = digraphActions(~any(isnan(meanCol),2),:);
		end
		
		function digraphActions = extractPAngraphs(keystrokes,full)
			% Store strings in one cell string:
			[uStrings, iUniq] = FeatureExtractor.getUniqueDigraphs(keystrokes);
			Values = cell2mat(keystrokes(:, [2, 4]));
			validValues = Values(:, 2) < FeatureExtractor.maxFlightTime;
			% Pre-allocate memory for cell array
			if full
				digraphActions = cell(length(uStrings),14);
			else
				digraphActions = cell(length(uStrings),10);
			end
			uStringsCell = cellstr(uStrings);
			% todo: remove column two, and correct the usage in matcher etc
			
			digraphActions(:, 1) = strcat(uStringsCell(:, 1), uStringsCell(:,2));
			digraphActions(:, 2) = uStringsCell(:, 2);

			for ii = 1:length(uStrings)
				% Find rows containing the current unique digraph
				occurIndices = find(iUniq == ii & validValues);
				[ppO,~,rpO,~] = ... These include outliers.
					FeatureExtractor.getDigraphLats(occurIndices, keystrokes);
				if length(ppO) > 1
					pp = FeatureExtractor.removeOutliers(ppO);
					rp = FeatureExtractor.removeOutliers(rpO);
				else
					pp = ppO;
					rp = rpO;
				end
				%Return digraphs with latencies
				digraphActions(ii,3:6) = {nanmean(pp),[],nanmean(rp),[]};
				digraphActions(ii,7:10) = {nanstd(pp),[],nanstd(rp),[]};
				
				if full
					%pr = FeatureExtractor.removeOutliers(prO);
					%rr = FeatureExtractor.removeOutliers(rrO);
					digraphActions(ii,11:14) = {pp,[],rp,[]};
				end
			end
			% remove rows without valid latencies
			meanCol = cell2mat(digraphActions(:,3));
			digraphActions = digraphActions(~any(isnan(meanCol),2),:);
		end
		
		function [uStrings,iUniq] = getUniqueDigraphs(keystrokes)
			Strings  = keystrokes(:, [1, 3]);
			[uStrings, ~, iUniq] = unique(string(Strings), 'rows');
		end
		
		function probe = createDiProbe(digraphRow, nextRow)
			%CREATEDIPROBE Creates a digraph probe.
			%	The digraphRow parameter is expected to be the row
			%	containing BOTH characters in the digraph. nextRow is the
			%	row after, which is needed to calculate latencies.
			probe = cell(1,6);
			probe{1} = digraphRow{1};
			probe{2} = digraphRow{3};
			
			[pp,pr,rp,rr] = FeatureExtractor.calcLats(digraphRow, nextRow);
			probe{3} = pp;
			probe{4} = pr;
			probe{5} = rp;
			probe{6} = rr;
		end
		
		function [pps,prs,rps,rrs] = getDigraphLats(occurIndices, keystrokes)
			pps = NaN(1, length(occurIndices));
			prs = NaN(1, length(occurIndices));
			rps = NaN(1, length(occurIndices));
			rrs = NaN(1, length(occurIndices));
			
			for jj = 1:length(occurIndices)
				% todo: avoid using this if statement inside loop.
				if occurIndices(jj) ~= length(keystrokes)
					digraphRow = keystrokes(occurIndices(jj),:);
					nextRow = keystrokes(occurIndices(jj)+1,:);
					nextKeyIsCorrect = strcmp(digraphRow{3}, nextRow{1});
					
					if nextKeyIsCorrect
						[pp,pr,rp,rr] = FeatureExtractor.calcLats(digraphRow, nextRow);
						pps(jj) = pp;
						prs(jj) = pr;
						rps(jj) = rp;
						rrs(jj) = rr;
					end
				end
			end
		end
		
		function [pp,pr,rp,rr] = calcLats(digraphRow, nextRow)
			pp = digraphRow{2} + digraphRow{4};
			pr = digraphRow{2} + digraphRow{4}+nextRow{2};
			rp = digraphRow{4};
			rr = digraphRow{4} + nextRow{2};
		end
		
		function [pps,prs,rps,rrs] = getPALats(digOccurIndices, keystrokes)
			pps = NaN(1, length(digOccurIndices));
			prs = NaN(1, length(digOccurIndices));
			rps = NaN(1, length(digOccurIndices));
			rrs = NaN(1, length(digOccurIndices));
			
			for jj = 1:length(digOccurIndices)
				% todo: avoid using this if statement inside loop.
				if digOccurIndices(jj) ~= length(keystrokes)
					firstRow = keystrokes(digOccurIndices(jj),:);
					secondRow = keystrokes(digOccurIndices(jj)+1,:);
					secKeyIsCorrect = strcmp(firstRow{3}, secondRow{1});
					
					if secKeyIsCorrect
						[pp,pr,rp,rr] = FeatureExtractor.calcLats(firstRow, secondRow);
						pps(jj) = pp;
						prs(jj) = pr;
						rps(jj) = rp;
						rrs(jj) = rr;
						%{
						if digOccurIndices(jj)+2 ~= length(keystrokes) && ...
								secondRow{4} < FeatureExtractor && ...
								strcmp(secondRow{3}, keystrokes(digOccurIndices(jj)+2),1)
							thirdRow = keystrokes(digOccurIndices(jj)+2,:);
						
						end
						%}
					end
				end
			end
		end
		
		function withoutOutliers = removeOutliers(myData)
			outliers = isoutlier(myData, 'quartiles');
			withoutOutliers = myData(~outliers);
		end
		
	end
end

