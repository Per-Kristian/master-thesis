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
			
			for i=1:length(uniqueChars)
				singleActions{i,1} = uniqueChars(i);
				indices = find(strcmp(keystrokes(:,1), ...
					uniqueChars{i}));
				singleActions{i,2} = cell2mat(keystrokes(indices, 2));
			end
		end
		%{
		function digraphActions = extractDigraphActions(keystrokes)
			uniqueDigraphs = cell(unique(cell2table(keystrokes(:,[1 2]))));
			indices = find(strcmp(keystrokes(:,1), ...
				uniqueDigraphs{}
			
		end
		%}
	end
end

