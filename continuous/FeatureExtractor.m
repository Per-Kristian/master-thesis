classdef FeatureExtractor
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess = private)
		singles
		digraphs
		uniqueChars
	end
	
	methods (Static)
		function singleActions = extractSingleActions(keystrokes)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			
			uniqueChars = unique(keystrokes(:,1));
			singleActions = cell(length(uniqueChars), 4);
			
			for ii=1:length(uniqueChars)
				singleActions{ii,1} = uniqueChars(ii);
				%todo: retreive indices from unique instead
				indices = find(strcmp(keystrokes(:,1), ...
					uniqueChars{ii}));
				singleActions{ii,2} = cell2mat(keystrokes(indices, 2));
				singleActions{ii,3} = mean(singleActions{ii,2});
				singleActions{ii,4} = std(singleActions{ii,2});
			end
		end
		
		function digraphActions = extractDigraphActions(keystrokes)
			% Store strings in one cell string:
			Strings  = keystrokes(:, [1, 3]);
			[uStrings, iStrings, iUniq] = unique(string(Strings), 'rows');
			Values = cell2mat(keystrokes(:, [2, 4]));
			% todo Do we really need to check duration here? remDur.
			validValues = (Values(:, 1) < 100000 & Values(:, 2) < 1500);
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
					[mean(pp),mean(pr),mean(rp),mean(rr)];
				digraphActions{ii,8} = [std(pp),std(pr),std(rp),std(rr)];
			end
			
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
		
		function [pp,pr,rp,rr] = getRefLats(occurIndices, keystrokes)
			pp = zeros(1, length(occurIndices));
			pr = zeros(1, length(occurIndices));
			rp = zeros(1, length(occurIndices));
			rr = zeros(1, length(occurIndices));
			
			for jj = 1:length(occurIndices)
				% todo: avoid using this if statement inside loop.
				if occurIndices(jj) ~= length(keystrokes)
					digraphRow = keystrokes(occurIndices(jj),:);
					nextRow = keystrokes(occurIndices(jj)+1,:);
					lats = calcLats(digraphRow, nextRow);
					pp(jj) = lats(1);
					pr(jj) = lats(2);
					rp(jj) = lats(3);
					rr(jj) = lats(4);
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
			end
		end
		
		%{
		function digraphActions = extractDigraphActions(keystrokes)
			% Convert keystroke structure to a table due to unique()
			% not supporting combinations of cellarray columns
			uniqueDigraphsTable = unique(cell2table( ... 
				keystrokes(:,[1 3])), 'rows');
			uniqueDigraphs = table2cell(uniqueDigraphsTable);
			
			% Ignore rows with 'BREAK' in column 4, as this symbolizes a
			% pause in keystroke recording.
			% withoutBreak = uniqueDigraphs( ... 
			%	find(~strcmp(uniqueDigraphs(:,2), 'BREAK')), :);
			
			% Pre-allocate memory for cell array
			digraphActions = cell(length(uniqueDigraphs),6);
			
			digraphActions(:, 1:2) = uniqueDigraphs(:, 1:2);

			for ii = 1:length(uniqueDigraphs)
				% Find rows containing the current unique digraph
				occurrenceIndices = find( ...
					strcmp(keystrokes(:,1), uniqueDigraphs{ii,1}) & ...
					strcmp(keystrokes(:,3), uniqueDigraphs{ii,2}) & ...
					cell2mat(keystrokes(:,2)) < 100000 & ...
					cell2mat(keystrokes(:,4)) < 2000);
				%Maybe check here if the nextkey is correct.
			end
			
				occurrences = keystrokes(occurrenceIndices, :);
				
				% Preallocate memory for the four different latencies to be
				% calculated for every occurrence of the current digraph.
				%[pp, pr, rp, rr] = zeros(1, length(occurrenceIndices));
				pp = zeros(1, length(occurrenceIndices));
				pr = zeros(1, length(occurrenceIndices));
				rp = zeros(1, length(occurrenceIndices));
				rr = zeros(1, length(occurrenceIndices));
				
				for jj = 1:length(occurrenceIndices)
					digraphRow = keystrokes(occurrenceIndices(jj),:);
					nextRow = keystrokes(occurrenceIndices(jj)+1,:);
					%rpLatency = keystrokes{occurrenceIndices(jj),4};
					rpLatency = digraphRow{4};
					% Check if the first key in the next row is the correct
					% one. If not, the behavior logging tool may have been
					% paused at that point, or some error may have occurred
					% during keystroke logging.
					nextKeyIsCorrect = strcmp(digraphRow{3}, nextRow{1});
					if nextKeyIsCorrect && rpLatency < 2000
						%{
						pp = [pp digraphRow{2} + digraphRow{4}];
						pr = [pr digraphRow{2} + digraphRow{4}+nextRow{2}];
						rp = [rp rpLatency];
						rr = [rr digraphRow{4} + nextRow{2}];
						%}
						pp(jj) = digraphRow{2} + digraphRow{4};
						pr(jj) = digraphRow{2} + digraphRow{4}+nextRow{2};
						rp(jj) = rpLatency;
						rr(jj) = digraphRow{4} + nextRow{2};
					end
				end
				%validDigraphs = occurrences((occurrences{:,4}- ...
				%	occurrences{:,2})<2000);
				%if 
				digraphActions{ii,3} = pp;
				digraphActions{ii,4} = pr;
				digraphActions{ii,5} = rp;
				digraphActions{ii,6} = rr;
			end
			
			digraphActions = uniqueDigraphs;
			
			%indices = find(strcmp(keystrokes(:,1), ...
			%	uniqueDigraphs{}))
			
		end
		%}
		
	end
end

