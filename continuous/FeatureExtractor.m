classdef FeatureExtractor
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        singles
        digraphs
    end
    
    methods
        function obj = FeatureExtractor(keystrokes)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            
            obj.singles = extractSingleActions(obj, keystrokes);
            %obj.digraphs = extractDigraphActions(sample);
        end
        
        function singleActions = extractSingleActions(obj, keystrokes)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
			
            uniqueChars = unique(keystrokes(:,1));
            valueSets = cell(length(uniqueChars), 2);
            
            for i=1:length(uniqueChars)
                valueSets{i,1} = uniqueChars(i);
                %indices = find(strcmp(keystrokes(:,1), uniqueChars{i}));
                indices = keystrokes(strcmp(keystrokes(:,1), ...
                                                    uniqueChars{i}));
                %valueSets{i,2} = cell2mat(keystrokes(indices, 2));
            end
            
            singleActions = valueSets;
            
        end
    end
end

