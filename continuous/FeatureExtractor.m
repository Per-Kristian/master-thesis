classdef FeatureExtractor
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess = private)
		singles
		digraphs
		uniqueChars
	end
	
	methods (Static)
		%{
function obj = FeatureExtractor()
           
    end
        
function obj = FeatureExtractor(keystrokes)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            
            obj.uniqueChars = unique(keystrokes(:,1));
            obj.singles = extractSingleActions(obj, keystrokes);
            %obj.digraphs = extractDigraphActions(obj, keystrokes);
            
        end
		%}
		function singleActions = extractSingleActions(keystrokes)
			%METHOD1 Summary of this method goes here
			%   Detailed explanation goes here
			
			uniqueChars = unique(keystrokes(:,1));
			singleActions = cell(length(uniqueChars), 2);
			
			for ii=1:length(uniqueChars)
				singleActions{ii,1} = uniqueChars(ii);
				%todo: retreive indices from unique instead
				indices = find(strcmp(keystrokes(:,1), ...
					uniqueChars{ii}));
				singleActions{ii,2} = cell2mat(keystrokes(indices, 2));
			end
		end
		
		function digraphActions = extractDigraphActions(keystrokes)
			% Convert keystroke structure to a table due to unique()
			% not supporting combinations of cellarray columns
			uniqueDigraphsTable = ... 
				unique(cell2table(keystrokes(:,[1 3])), 'rows');
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
				occurrenceIndices = find(strcmp(keystrokes(:,1), ...
					uniqueDigraphs{ii,1}) & strcmp(keystrokes(:,3), ...
					uniqueDigraphs{ii,2}) & keystrokes(:,2)<100000 & ... 
					keystrokes{:,4}<2000);
				%occurrences = keystrokes(occurrenceIndices, :);
				
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
		
	end
end

