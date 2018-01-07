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
			
			%pre-allocate memory for cell array
			digraphActions = cell(length(uniqueDigraphs),6);
			
			digraphActions{:,1:2} = uniqueDigraphs{:,1:2};
			for ii=1:length(uniqueDigraphs)
				%digraphActions{ii,1} = uniqueDigraphs{ii,1};
				%digraphActions{ii,2} = uniqueDigraphs{ii,2};
				
			end
			
			digraphActions = uniqueDigraphs;
			
			%indices = find(strcmp(keystrokes(:,1), ...
			%	uniqueDigraphs{}))
			
		end
		
	end
end

